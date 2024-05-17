defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :odds, :integer
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :type, :string
    field :user_id, :id
    field :market_id, :id

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

    #You manage the operations for creating SupervisorMarketBet processes. They are created when a market is created.

  end

  defmodule SupervisorMarketBet do
    use Supervisor
    def start_link() do
      #Supervisor.start_link(__MODULE__, [], name: :market_bet_supervisor)
    end

    def init(_) do
      #children = [
      #  {Betunfair.Bet.OperationsBet, []}
      #]
      #Supervisor.init(children, strategy: :one_for_one)
    end

    # A SupervisorMarketBet creates a OperationsBet process as a child of him when a bet is created.
  end

  defmodule GestorMarketBet do
    use GenServer

    def start_link([]) do
      #GenServer.start_link(__MODULE__, [], name: :market_bet_gestor)
    end

    def init(args) do
      #{:ok, args}
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
