defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :odds, :float
    field :original_stake, :float
    field :remaining_stake, :float
    field :type, :string
    field :user_id, :id
    field :market_id, :id

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorBet do
    use Supervisor
    def start_link(_) do
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
        {Betunfair.Bet.GestorMarketBet, [market_id]}
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
      {:ok, args}
    end

    def bet_back(user_id, market_id, stake, odds) do
      #You manage the operations for creating a bet back.
    end

    def bet_lay(user_id, market_id, stake, odds) do
      #You manage the operations for creating a bet lay.
    end

    #You manage the operations for creating OperationsBet processes. They are created when a bet is created.

  end

  defmodule OperationsBet do
    use GenServer

    def start_link(args) do
      #GenServer.start_link(__MODULE__, args, name: args)
    end

    def init(args) do
      #{:ok, args}
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
    |> cast(attrs, [:odds, :type, :original_stake, :remaining_stake])
    |> validate_required([:odds, :type, :original_stake, :remaining_stake])
  end
end
