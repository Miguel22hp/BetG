defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :odds, :integer #TODO: this (and in Ecto) should be a float
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :type, :string
    #adding the user_id and market_id as a FK on Ecto Schema
    belongs_to :user, Betunfair.User
    belongs_to :market, Betunfair.Market

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorBet do
    use Supervisor
    def start_link() do
      Supervisor.start_link(__MODULE__, [], name: :bet_supervisor)
    end

    def init(_) do
      children = [
        {Betunfair.Bet.GestorBet, []}
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end

    # A SupervisorBet creates a SupervisorMarketBet process as a child of him when a market is created.
    #
  end


  defmodule GestorBet do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :bet_gestor)
    end

    def init(args) do
      {:ok, args}
    end

    def handle_call({:add_child_operation, market_id}, _from, state) do
      child_name = :"supervisor_bet_market#{market_id}"
      child_spec = Betunfair.Bet.SupervisorMarketBet.child_spec({:args, child_name, market_id})
      case Supervisor.start_child(:bet_supervisor, child_spec) do
        {:ok, _pid} ->
          {:reply, {:ok}, state}
        {:error, reason} ->
          {:reply, {:error, reason, "ERROR AL CREAR EL HIJO"}, state}
      end

    end

    #You manage the operations for creating SupervisorMarketBet processes. They are created when a market is created.
    def add_child_operation( market_id) do
      GenServer.call(:bet_gestor, {:add_child_operation, market_id})
    end

  end

  defmodule SupervisorMarketBet do
    use Supervisor

    def child_spec({:args, child_name, market_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [market_id]},
        type: :supervisor,
        restart: :permanent,
        shutdown: 500
      }
    end


    def start_link(market_id) do
      child_name = :"supervisor_bet_market_#{market_id}"
      Supervisor.start_link(__MODULE__, market_id, name: child_name)
    end

    def init(market_id) do
      children = [
        {Betunfair.Bet.GestorMarketBet, {:args, market_id}}
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end

    # A SupervisorMarketBet creates a OperationsBet process as a child of him when a bet is created.
  end

  defmodule GestorMarketBet do
    use GenServer

    def start_link(market_id) do
      child_name = :"gestor_bet_market_#{market_id}"
      GenServer.start_link(__MODULE__, market_id, name: child_name)
    end

    def init(args) do
      IO.puts("creando gestor market bet #{args}")
      {:ok, args}
    end

    def child_spec({:args, market_id}) do
      child_name = :"gestor_bet_market_#{market_id}"
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [market_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    def handle_call({:back_bet, user_id, market_id, stake, odds}, _from, state) do
      case insert_bet(user_id, market_id, stake, odds, "back") do
        {:ok, bet} ->
          child_name = :"bet_#{bet.id}"
          child_spec = Betunfair.Bet.OperationsBet.child_spec({:args, bet.id, child_name})
          process_name = :"supervisor_bet_market_#{market_id}"
          case Supervisor.start_child(process_name, child_spec) do
            {:ok, _pid} ->
              {:reply, {:ok, bet.id}, state}
            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end

    #@spec bet_back(user_id :: user_id(), market_id :: market_id(), stake :: integer(), odds :: integer()) :: {:ok, bet_id()}
    def bet_back(user_id, market_id, stake, odds) do
      process_name = :"gestor_bet_market_#{market_id}"
      GenServer.call(process_name, {:back_bet, user_id, market_id, stake, odds})
    end

    def bet_lay(user_id, market_id, stake, odds) do
      #You manage the operations for creating a bet lay.
    end

    #You manage the operations for creating OperationsBet processes. They are created when a bet is created.
    def insert_bet(user_id, market_id, stake, odds, type) do
      #validating input
      case Betunfair.Repo.get(Betunfair.User, user_id) do
        nil ->
          {:error, "user with id #{user_id} doesn't exist"}
        user ->
          if stake > user.balance do
             {:error, "Insufficient balance for user with id #{user_id}: stake #{stake}$ is greater than user's balance #{user.balance}$"}
          else
            case Betunfair.Repo.get(Betunfair.Market, market_id) do
              nil ->
                {:error, "user with id #{user_id} doesn't exist"}
              _market ->
                changeset = Betunfair.User.changeset(user, %{balance: user.balance - stake})
                case Betunfair.Repo.update(changeset) do
                  {:ok, user} ->
                    IO.puts("updated user #{user_id} balance due to new inserted bet")
                    {:ok, user}
                  {:error, changeset} ->
                    {:error, "Couldn't modify user balance for user #{user_id}: #{inspect(changeset.errors)}"}
                  end
                changeset = Betunfair.Bet.changeset(%Betunfair.Bet{}, %{user_id: user_id, market_id: market_id, original_stake: stake, remaining_stake: stake, odds: odds, type: type})
                case Betunfair.Repo.insert(changeset) do
                  {:ok, bet} ->
                    {:ok, bet}
                  {:error, changeset} ->
                    {:error, "Couldn't create the bet for user #{user_id}: #{inspect(changeset.errors)}"}
                end
              end
          end
        end
    end
  end

  defmodule OperationsBet do
    use GenServer

    def start_link(bet_id) do
      child_name = :"bet_#{bet_id}"
      GenServer.start_link(__MODULE__, bet_id, name: child_name)
    end

    def init(args) do
      {:ok, args}
    end

    def child_spec({:args, bet_id, child_name}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [bet_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    def bet_get(id) do
      #You manage the operations for getting a bet.
    end

    def bet_cancel(id) do
      #cancels the parts of a bet that has not been matched yet (remaining_stake).
    end

    # You manage the operations that can be done in a bet.

  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :market_id, :odds, :type, :original_stake, :remaining_stake])
    |> validate_required([:user_id, :market_id, :odds, :type, :original_stake, :remaining_stake])
    |> assoc_constraint(:user)
    |> assoc_constraint(:market)
  end
end
