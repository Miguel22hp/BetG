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

    @moduledoc """
    This supervisor will supervise and manage the process of matching bets and
    lays inside a market. There is one Matched supervisor for each market.
  """

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(matched, attrs) do
    matched
    |> cast(attrs, [])
    |> validate_required([])
  end

  defmodule SupervisorMatched do
    use Supervisor

    @doc """
    Starts the Supervisor for Matched establishing the name :matched_supervisor.
    """
    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: :matched_supervisor)
    end

    @doc """
    Initializes the Supervisor with the child processes to be supervised, with a one_for_one
    strategy.
    """
    def init(_) do
      children = [
        {Betunfair.Matched.GestorMatched, []}
      ]
      # IO.puts("Matched supervisor started ")
      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defmodule GestorMatched do
    use GenServer

    @moduledoc """
      This process will be supervised by the matched supervisor.
      The matched manager is a GenServer that receives the matched calls to execute the matched algorithm.
    """

    @doc """
    Starts the GestorMatched GenServer with the given arguments.
    """
    @spec start_link(any()) :: GenServer.on_start()
    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :matched_gestor)
    end

    @doc """
    Initializes the GestorMatched GenServer with the given arguments.
    """
    @spec init(any()) :: {:ok, any()}
    def init(args) do
      # IO.puts("Matchaming gestor started")
      {:ok, args}
    end

    @spec handle_call({:add_child_operation, integer()}, GenServer.from(), any()) :: {:reply, {:ok | {:error, any()}}, any()}
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

    @spec add_child_operation(integer()) :: :ok
    def add_child_operation(market_id) do
      GenServer.call(:matched_gestor, {:add_child_operation, market_id})
    end

  end

  defmodule OperationsMatched do
    alias Betunfair.{Bet, Matched}
    use GenServer
    import Ecto.Query, only: [from: 2]

    @moduledoc """
      This process will be supervised by the matched supervisor.
      The OperationsMatched GenServer is responsible for matching bets and lays inside a market.
    """

    @doc """
    Returns the child specification for a new OperationsMatched GenServer.
    """
    @spec child_spec({:args, atom(), integer()}) :: Supervisor.child_spec()
    def child_spec({:args, child_name, match_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [match_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    @doc """
    Starts the OperationsMatched GenServer for the given match ID.
    """
    @spec start_link(integer()) :: GenServer.on_start()
    def start_link(match_id) do
      child_name = :"match_#{match_id}"
      GenServer.start_link(__MODULE__, match_id, name: child_name)
    end

    @spec init(integer()) :: {:ok, integer()}
    def init(match_id) do
      # IO.puts("Matcher created with ID: #{match_id}")
      {:ok, match_id}
    end

    @spec handle_call({:market_match, market_id :: integer()}, GenServer.from(), any()) :: {:reply, {:ok}, any()}
    def handle_call({:market_match, market_id}, _from, state) do
      match_bets(market_id)
      {:reply, {:ok}, state}
    end

    # Step 1: Fetch pending back and lay bets for the specific market
    @doc """
    Matches bets for the given market ID by
    fetching pending back and lay bets from the database and iterating
    through potential matches.
    """
    @spec match_bets(market_id :: integer()) :: :ok
    def match_bets(market_id) do
      back_bets = fetch_pending_back_bets(market_id)
      lay_bets = fetch_pending_lay_bets(market_id)
      #IO.inspect(length(back_bets))
      #IO.inspect(length(lay_bets))
      match_bets_loop(back_bets, lay_bets)
    end

    # Step 2-6: Iterate through potential matches until no more matches
    @doc """
    Iterates through potential matches until no more matches can be found.
    If a match is found, the stakes are updated in the database, if the lay stake is empty,
    the next lay is retrieved and otherwise, the next back is retrieved. The process is repeated
    until no more matches can be found between bets and lays.
    """
    @spec match_bets_loop(back_bets :: list(), lay_bets :: list()) :: :ok
    def match_bets_loop([], _), do: :ok
    def match_bets_loop(_, []), do: :ok

    @spec match_bets_loop(back_bets :: [map()], lay_bets :: [map()]) :: :ok
    def match_bets_loop([back_bet | rest_back_bets], [lay_bet | rest_lay_bets]) do
      if potential_match?(back_bet, lay_bet) do
        {matched_amount, new_back_stake, new_lay_stake} = calculate_matched_amount(back_bet, lay_bet)
        update_bet_stakes(back_bet, lay_bet, new_back_stake, new_lay_stake)
        if new_back_stake == 0.0 do
          balance_empty = back_bet.remaining_stake * back_bet.odds
          balance_remain = back_bet.remaining_stake
          empty_stake = "back"
          save_matched_bet(back_bet.id, lay_bet.id, matched_amount, balance_empty, balance_remain, empty_stake)
          # IO.inspect("Back bet empty #{new_back_stake}")
        else
          balance_empty = back_bet.remaining_stake - new_back_stake
          balance_remain = lay_bet.remaining_stake
          empty_stake = "lay"
          # IO.inspect("Lay bet stake: #{new_lay_stake}")
          # IO.inspect("Back bet stake: #{new_back_stake}")
          save_matched_bet(back_bet.id, lay_bet.id, matched_amount, balance_empty, balance_remain, empty_stake)
        end

        updated_back_bet = %Bet{back_bet | remaining_stake: new_back_stake}
        updated_lay_bet = %Bet{lay_bet | remaining_stake: new_lay_stake}

        #IO.puts("Matched amount: #{matched_amount}, new_back_stake: #{new_back_stake}, new_lay_stake: #{new_lay_stake}")
        # IO.puts("Updated back bet: odds #{updated_back_bet.odds}, remaining stake #{updated_back_bet.remaining_stake}, updated lay bet: odds #{updated_lay_bet.odds}, remaining stake #{updated_lay_bet.remaining_stake}")

        updated_back_bets = if updated_back_bet.remaining_stake > 0, do: [updated_back_bet | rest_back_bets], else: rest_back_bets
        updated_lay_bets = if updated_lay_bet.remaining_stake > 0, do: [updated_lay_bet | rest_lay_bets], else: rest_lay_bets

        match_bets_loop(updated_back_bets, updated_lay_bets)
      else
        match_bets_loop(rest_back_bets, [lay_bet | rest_lay_bets])
      end
    end

    # Step 2: Find potential matches
    @doc """
    Determines if a back bet and lay bet can potentially match, this is bet.odds <= lays.odds
    """
    @spec potential_match?(back_bet :: map(), lay_bet :: map()) :: boolean()
    def potential_match?(back_bet, lay_bet) do
      back_bet.odds <= lay_bet.odds
    end

    # Step 3: Calculate matched amount
    @doc """
    Calculates the matched amount and new stakes for a back bet and lay bet,
    returns the matched amount and the remaining stakes of the back and lay bets.
    """
    @spec calculate_matched_amount(back_bet :: map(), lay_bet :: map()) :: {matched_amount :: float(), new_back_stake :: float(), new_lay_stake :: float()}
    def calculate_matched_amount(back_bet, lay_bet) do
      if (back_bet.remaining_stake * back_bet.odds - back_bet.remaining_stake) >= lay_bet.remaining_stake do
        lay_stake_consumed = lay_bet.remaining_stake / (back_bet.odds - 1)
        {lay_stake_consumed, round_to_two(back_bet.remaining_stake - lay_stake_consumed), 0.0}
      else
        back_stake_consumed = back_bet.remaining_stake * back_bet.odds - back_bet.remaining_stake
        {back_stake_consumed, 0.0, round_to_two(lay_bet.remaining_stake - back_stake_consumed)}
      end
    end

    @doc """
    Updates the stakes for a back bet and lay bet in the database.
    """
    @spec update_bet_stakes(back_bet :: map(), lay_bet :: map(), new_back_stake :: float(), new_lay_stake :: float()) :: :ok
    def update_bet_stakes(back_bet, lay_bet, new_back_stake, new_lay_stake) do
      updated_back_bet_changeset =
        Bet.changeset(back_bet, %{
          odds: back_bet.odds,
          original_stake: back_bet.original_stake,
          remaining_stake: new_back_stake,
          type: back_bet.type,
          user_id: back_bet.user_id,
          market_id: back_bet.market_id
        })

      updated_lay_bet_changeset =
        Bet.changeset(lay_bet, %{
          odds: lay_bet.odds,
          original_stake: lay_bet.original_stake,
          remaining_stake: new_lay_stake,
          type: lay_bet.type,
          user_id: lay_bet.user_id,
          market_id: lay_bet.market_id
        })

      Betunfair.Repo.transaction(fn ->
        Betunfair.Repo.update!(updated_back_bet_changeset)
        Betunfair.Repo.update!(updated_lay_bet_changeset)
      end)
    end

    # Step 5: Record matched bets
    @doc """
    Saves a matched bet in the database, introducing the bet and lays id, the matched amount,
    the expected winnings of the back and the bet, and which one had it stake emptied.
    """
    @spec save_matched_bet(back_bet_id :: integer(), lay_bet_id :: integer(), matched_amount :: float(), balance_empty :: float(), balance_remain :: float(), empty_stake :: String.t()) :: :ok
    def save_matched_bet(back_bet_id, lay_bet_id, matched_amount, balance_empty, balance_remain, empty_stake) do
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

    @doc """
    Fetches pending back bets for a given market ID, ordered by odds in ascending order.
    """
    @spec fetch_pending_back_bets(market_id :: integer()) :: list()
    def fetch_pending_back_bets(market_id) do
      query = from(b in Bet, where: b.market_id == ^market_id and b.remaining_stake > 0.0 and b.type == "back", order_by: [asc: b.odds])
      Betunfair.Repo.all(query)
    end

    @doc """
    Fetches pending lay bets for a given market ID, ordered by odds in descending order.
    """
    @spec fetch_pending_lay_bets(market_id :: integer()) :: list()
    def fetch_pending_lay_bets(market_id) do
      query = from(l in Bet, where: l.market_id == ^market_id and l.remaining_stake > 0.0 and l.type == "lay", order_by: [desc: l.odds])
      Betunfair.Repo.all(query)
    end

    @doc """
    Rounds a float value to two decimal places, for currency values.
    """
    @spec round_to_two(float()) :: float()
    defp round_to_two(value) do
      Float.round(value, 2)
    end

  end

end
