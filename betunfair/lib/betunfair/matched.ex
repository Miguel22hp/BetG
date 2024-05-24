defmodule Betunfair.Matched do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matched" do

    field :id_bet_backed, :id
    field :id_bet_layed, :id
    field :matched_amount, :float
    field :balance_empty_stake, :float
    field :balance_remain_stake, :float
    field :empty_stake, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(matched, attrs) do
    matched
    |> cast(attrs, [])
    |> validate_required([])
  end

  defmodule SupervisorMatched do
    use Supervisor
    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: :matched_supervisor)
    end

    def init(_) do
      children = [
        {Betunfair.Matched.GestorMatched, []}
      ]
      IO.puts("Matched supervisor started ")
      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defmodule GestorMatched do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :matched_gestor)
    end

    def init(args) do
      IO.puts("Matchaming gestor started")
      {:ok, args}
    end

    def handle_call({:add_child_operation, market_id}, _from, state) do
      child_name = :"match_#{market_id}"
      child_spec = Betunfair.Matched.OperationsMatched.child_spec({:args, child_name, market_id})
      case Supervisor.start_child(:matched_supervisor, child_spec) do
        {:ok, _pid} ->
          {:reply, {:ok}, state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end

    def add_child_operation( market_id) do
      GenServer.call(:matched_gestor, {:add_child_operation, market_id})
    end

  end

  defmodule OperationsMatched do
    alias Betunfair.{Bet, Matched}
    use GenServer
    import Ecto.Query, only: [from: 2]

    def child_spec({:args, child_name, match_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [match_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    def start_link(match_id) do
      child_name = :"match_#{match_id}" # nombre del hijo
      GenServer.start_link(__MODULE__, match_id, name: child_name)
    end

    def init(match_id) do
      IO.puts("Matcher created with ID: #{match_id}")
      {:ok, match_id}
    end

    def handle_call({:market_match, market_id}, _from, state) do
      match_bets(market_id)
      {:reply, {:ok}, state}
    end

    # Step 1: Fetch pending back and lay bets for the specific market
    def match_bets(market_id) do
      back_bets = fetch_pending_back_bets(market_id) # Obtains all the back bets
      lay_bets = fetch_pending_lay_bets(market_id) # Obtains all the lay bets
      #IO.inspect(length(back_bets))
      #IO.inspect(length(lay_bets))
      match_bets_loop(back_bets, lay_bets)
    end

    # Step 2-6: Iterate through potential matches until no more matches
    def match_bets_loop([], _), do: :ok
    def match_bets_loop(_, []), do: :ok

    def match_bets_loop([back_bet | rest_back_bets], [lay_bet | rest_lay_bets]) do
      # Show the bets that are being matched
      if potential_match?(back_bet, lay_bet) do
        {matched_amount, new_back_stake, new_lay_stake} = calculate_matched_amount(back_bet, lay_bet)
        update_bet_stakes(back_bet, lay_bet, new_back_stake, new_lay_stake)
        if new_back_stake == 0.0 do
          balance_empty = back_bet.remaining_stake * back_bet.odds
          balance_remain = back_bet.remaining_stake
          empty_stake = "back"
          save_matched_bet(back_bet.id, lay_bet.id, matched_amount, balance_empty, balance_remain, empty_stake)
          IO.inspect("Back bet empty #{new_back_stake}")
        else
          balance_empty = back_bet.remaining_stake - new_back_stake
          balance_remain = lay_bet.remaining_stake
          empty_stake = "lay"
          IO.inspect("Lay bet stake: #{new_lay_stake}")
          IO.inspect("Back bet stake: #{new_back_stake}")
          save_matched_bet(back_bet.id, lay_bet.id, matched_amount, balance_empty, balance_remain, empty_stake)
        end

        updated_back_bet = %Bet{back_bet | remaining_stake: new_back_stake}
        updated_lay_bet = %Bet{lay_bet | remaining_stake: new_lay_stake}

        #IO.puts("Matched amount: #{matched_amount}, new_back_stake: #{new_back_stake}, new_lay_stake: #{new_lay_stake}")
        # IO.puts("Updated back bet: odds #{updated_back_bet.odds}, remaining stake #{updated_back_bet.remaining_stake}, updated lay bet: odds #{updated_lay_bet.odds}, remaining stake #{updated_lay_bet.remaining_stake}")

        updated_back_bets = if updated_back_bet.remaining_stake > 0, do: [updated_back_bet | rest_back_bets], else: rest_back_bets

        updated_back_bets = if updated_back_bet.remaining_stake > 0, do: [updated_back_bet | rest_back_bets], else: rest_back_bets
        updated_lay_bets = if updated_lay_bet.remaining_stake > 0, do: [updated_lay_bet | rest_lay_bets], else: rest_lay_bets

        match_bets_loop(updated_back_bets, updated_lay_bets)
      else
        match_bets_loop(rest_back_bets, [lay_bet | rest_lay_bets])
      end
    end

    # Step 2: Find potential matches
    def potential_match?(back_bet, lay_bet) do
      back_bet.odds <= lay_bet.odds
    end



  # Step 3: Calculate matched amount
  def calculate_matched_amount(back_bet, lay_bet) do
    if (back_bet.remaining_stake * back_bet.odds - back_bet.remaining_stake) >= lay_bet.remaining_stake do
      lay_stake_consumed = lay_bet.remaining_stake / (back_bet.odds - 1)
      {lay_stake_consumed, round_to_two(back_bet.remaining_stake - lay_stake_consumed), 0.0}
    else
      back_stake_consumed = back_bet.remaining_stake * back_bet.odds - back_bet.remaining_stake
      {back_stake_consumed, 0.0, round_to_two(lay_bet.remaining_stake - back_stake_consumed)}
    end
  end

    def update_bet_stakes(back_bet, lay_bet, new_back_stake, new_lay_stake) do
      # Create changesets for the updated bets
      updated_back_bet_changeset =
        Bet.changeset(back_bet, %{
          odds: back_bet.odds,
          original_stake: back_bet.original_stake,
          remaining_stake: (new_back_stake),
          type: back_bet.type,
          user_id: back_bet.user_id,
          market_id: back_bet.market_id
        })

      updated_lay_bet_changeset =
        Bet.changeset(lay_bet, %{
          odds: lay_bet.odds,
          original_stake: lay_bet.original_stake,
          remaining_stake: (new_lay_stake),
          type: lay_bet.type,
          user_id: lay_bet.user_id,
          market_id: lay_bet.market_id
        })

      # Execute the updates in a transaction
      Betunfair.Repo.transaction(fn ->
        Betunfair.Repo.update!(updated_back_bet_changeset)
        Betunfair.Repo.update!(updated_lay_bet_changeset)
      end)
    end

    # Step 5: Record matched bets
    def save_matched_bet(back_bet_id, lay_bet_id, matched_amount, balance_empty, balance_remain, empty_stake) do
      IO.puts("Matched amount: #{matched_amount}, balance_empty_stake: #{balance_empty}, balance_remain_stake: #{balance_remain}. Empty stake: #{empty_stake}")
      matched_bet = %Matched{
        id_bet_backed: back_bet_id,
        id_bet_layed: lay_bet_id,
        matched_amount: matched_amount,
        balance_empty_stake: balance_empty,
        balance_remain_stake: balance_remain,
        empty_stake: empty_stake
      }
      Betunfair.Repo.insert!(matched_bet)
      {:ok}
    end

    # Helper functions for database operations
    def fetch_pending_back_bets(market_id) do
      query = from(b in Bet, where: b.market_id == ^market_id and b.remaining_stake > 0.0 and b.type == "back", order_by: [asc: b.odds])
      Betunfair.Repo.all(query)
    end

    def fetch_pending_lay_bets(market_id) do
      query = from(l in Bet, where: l.market_id == ^market_id and l.remaining_stake > 0.0 and l.type == "lay", order_by: [desc: l.odds])
      Betunfair.Repo.all(query)
    end

    defp round_to_two(value) do
      Float.round(value, 2)
    end

  end

end
