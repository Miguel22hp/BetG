defmodule Betunfair.Market do
  use Ecto.Schema
  import Ecto.Changeset
  #alias Betunfair.Matched
  #alias Betunfair.Bet
  require Logger

  schema "markets" do
    field :description, :string
    field :name, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorMarket do
    use Supervisor

    @moduledoc """
      This supervisor will supervise the market manager and the market operations processes.
      It is created when the applications starts.
    """

    @doc """
      Starts the supervisor for the market processes. Establish the name of
      the supervisor :market_supervisor
    """
    @spec start_link(any) :: {:ok, pid()} | {:error, any()}
    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: :market_supervisor)
    end

    @doc """
      Initializes the supervisor with the children to be supervised. Load
      markets' processes from markets that are already in the database.
    """
    @spec init(any) :: {:ok, any}
    def init(_) do
      children = [
        {Betunfair.Market.GestorMarket, []}
      ]
      state = Supervisor.init(children, strategy: :one_for_one)
      Task.start(fn -> load_market() end)
      state
    end

    @spec load_market() :: :ok
    def load_market() do
      markets = Betunfair.Repo.all(Betunfair.Market)
      for market <- markets do
        createProcessMarket(market)
        createProcessBetSupervisor(market.id)
        createProcessMatched(market.id)
        Process.sleep(100) # Adds 100 ms delay between process creation sothey do not select the same PID
      end
      :ok
    end

    @spec createProcessMarket(market :: Betunfair.Market.t()) :: {nil | {:error, any()} | {:ok, :undefined | pid()} | {:ok, :undefined | pid(), any()}}
    def createProcessMarket(market) do
      child_name = :"market_#{market.id}"
      if Process.whereis(child_name) == nil do
        Supervisor.start_child(:market_supervisor, {Betunfair.Market.OperationsMarket, {:args, child_name, market.id}})
      end
    end

    @spec createProcessBetSupervisor(market_id ::  integer) :: {nil | {:error, any()} | {:ok, :undefined | pid()} | {:ok, :undefined | pid(), any()}}
    def createProcessBetSupervisor(market_id) do
      child_name = :"supervisor_bet_market_#{market_id}"
      if Process.whereis(child_name) == nil do
        child_spec = Betunfair.Bet.SupervisorMarketBet.child_spec({:args, child_name, market_id})
        Supervisor.start_child(:bet_supervisor, child_spec)
      end
    end

    @spec createProcessMatched(market_id ::  integer) :: {nil | {:error, any()} | {:ok, :undefined | pid()} | {:ok, :undefined | pid(), any()}}
    def createProcessMatched(market_id) do
      child_name = :"match_#{market_id}"
      if Process.whereis(child_name) == nil do
        Supervisor.start_child(:matched_supervisor, {Betunfair.Matched.OperationsMatched, {:args, child_name, market_id}})
      end
    end
  end

  defmodule GestorMarket do
    require Logger
    use GenServer

    @moduledoc """
      This process will be supervised by the market supervisor.
      The market manager is a GenServer that receives the market creation requests and creates the market and the process.
      It also returns the list of markets and the list of active markets.
      The process created will be supervised by the user supervisor.
    """

    @doc """
      Starts the GenServer for the user manager. Establish the name as :user_gestor.
    """
    @spec start_link(Enumerable.t()) :: {:ok, GenServer.t()} | {:error, any}
    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :market_gestor)

    end

    @doc """
      Initializes the GenServer with the arguments.
    """
    @spec init(any) :: {:ok, any}
    def init(args) do
      {:ok, args}
    end

    @spec handle_call({:market_create, name :: String.t(), description :: String.t()}, GenServer.from(), any) :: {{:reply, {:ok, market_id ::  integer}, any} | {:reply, {:error, reason :: String.t()}, any}}
    def handle_call({:market_create, name, description}, _from, state) do
      case Betunfair.Repo.get_by(Betunfair.Market, name: name) do
        nil ->
          # No hay ningún mercado con el mismo nombre, puedes proceder a crear el mercado
          # Aquí iría la lógica para crear el mercado
          case Betunfair.Market.GestorMarket.add_child_operation(name, description) do

            {:ok, market_id} ->
              # Create from GestorBet a SupervisorMarketBet process
              case Betunfair.Bet.GestorBet.add_child_operation(market_id) do
                {:ok} ->
                  case Betunfair.Matched.GestorMatched.add_child_operation(market_id) do
                    {:ok} ->
                      {:reply, {:ok, market_id}, state}
                    {:error, reason} ->
                      {:reply, {:error, reason}, state}
                  end
                {:error, reason} ->
                  {:reply, {:error, reason}, state}
              end
            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        _market ->
          # Ya existe un mercado con el mismo nombre, maneja este caso según tus necesidades
          # Por ejemplo, podrías devolver un error o lanzar una excepción
          {:reply, {:error, "A market with the same name already exists"}, state}
      end
    end

    @spec add_child_operation(name :: String.t(), description :: String.t()) :: {{:ok, market_id ::  integer} | {:error, reason :: String.t()}}
    def add_child_operation(name, description) do
      case insert_market(name, description) do
        {:ok, market} ->
          child_name = :"market_#{market.id}" #nombre del hijo
          child_spec = Betunfair.Market.OperationsMarket.child_spec({:args, child_name, market.id})
          case Supervisor.start_child(:market_supervisor, child_spec) do
            {:ok, _pid} ->
              {:ok, market.id}
            {:error, reason} ->
              {:error, reason}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end

    @spec insert_market(name :: String.t(), description :: String.t()) :: {{:ok, market :: Betunfair.Market.t()} | {:error, reason :: String.t()}}
    def insert_market(name, description) do
      changeset = Betunfair.Market.changeset(%Betunfair.Market{}, %{name: name, description: description, status: "active"})
      case Betunfair.Repo.insert(changeset) do
        {:ok, market} ->
          {:ok, market}
        {:error, changeset} ->
          {:error, "Market couldn't be inserted. The reason: #{inspect(changeset.errors)}"}
      end
    end

    @spec handle_call({:market_list}, GenServer.from(), any) :: {:reply, {:ok, market_ids :: Enumerable.t( integer)}, any}
    def handle_call({:market_list}, _from, state) do
      markets = Betunfair.Repo.all(Betunfair.Market)
      case markets do
        [] ->
          {:reply, {:ok, []}, state}
        _markets ->
          market_ids = Enum.map(markets, &(&1.id))
          {:reply, {:ok, market_ids}, state}
      end
    end

    @spec handle_call({:market_list_active}, GenServer.from(), any) :: {:reply, {:ok, market_ids :: Enumerable.t( integer)}, any}
    def handle_call({:market_list_active}, _from, state) do
      markets = Betunfair.Repo.all(Betunfair.Market)
      case markets do
        [] ->
          {:reply, {:ok, []}, state}
        _markets ->
          active_markets = Enum.filter(markets, fn market -> market.status == "active" end)
          market_ids = Enum.map(active_markets, &(&1.id))
          {:reply, {:ok, market_ids}, state}

      end
    end

    @doc """
      This function is used to create a new market. It will call the GenServer
      to create the market, if there is no market with the same name, and return
      the market_id if the market was created successfully. If the market was not
      created, it will return an error.
    """
    @spec market_create(name :: String.t(), description :: String.t()) :: {{:ok, market_id ::  integer} | {:error, reason :: String.t()}}
    def market_create(name, description) do
      case GenServer.call(:market_gestor, {:market_create, name, description}) do
        {:ok, market_id} ->
          {:ok, market_id}
        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
      This function is used to get the list of all markets. It will get the list of
      markets and return the market_ids if the list was obtained
      successfully. If the list was not obtained, it will return an error.
    """
    @spec market_list() :: {{:ok, market_ids :: Enumerable.t( integer)} | {:error, reason :: String.t()}}
    def market_list() do
      case GenServer.call(:market_gestor, {:market_list}) do
        {:ok, ids} ->
          {:ok, ids}
        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
      This function is used to get the list of all active markets. It will get the
      list of active markets and return the market_ids if the list was obtained
      successfully. If the list was not obtained, it will return an error.
    """
    @spec market_list_active() :: {{:ok, market_ids :: Enumerable.t( integer)} | {:error, reason :: String.t()}}
    def market_list_active() do
      case GenServer.call(:market_gestor, {:market_list_active}) do
        {:ok, ids} ->
          {:ok, ids}
        {:error, reason} ->
          {:error, reason}
      end
    end



  end

  defmodule OperationsMarket do
    use GenServer
    import Ecto.Query, only: [from: 2]
    require Logger
    #alias Betunfair.Repo

    @moduledoc """
      This process will be supervised by the market supervisor.
      The market operations is a GenServer that receives the market operations requests and performs the operations.
    """

    @doc """
      Defines the child specification for the market operations process.
    """
    @spec child_spec({:args, child_name :: String.t(), user_id :: Integer.t()}) :: Supervisor.Spec.t()
    def child_spec({:args, child_name, market_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [market_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    @doc """
      Starts the GenServer for the market operations.
      Establish the name as :market_(id of the market in the database)
    """
    @spec start_link(market_id ::  integer) :: {:ok, pid()} | {:error, any()}
    def start_link(market_id) do
      child_name = :"market_#{market_id}" #nombre del hijo
      GenServer.start_link(__MODULE__, market_id, name: child_name)
    end

    @doc """
      Initializes the GenServer with the market id.
    """
    @spec init(market_id ::  integer) :: {:ok, Integer.t()}
    def init(market_id) do
      {:ok, market_id}
    end

    @spec handle_call({:market_bets, market_id ::  integer, market :: Betunfair.Market.t()}, GenServer.from(), any()) :: {:reply, {:ok, Enumerable.t( integer)}, any()}
    def handle_call({:market_bets, market_id, _market}, _from, state) do
      query = from b in Betunfair.Bet, where: b.market_id == ^market_id
      bets = Betunfair.Repo.all(query)
      #crear un Enumerable.t con los id de las bets
      bet_ids = Enum.map(bets, &(&1.id))
      {:reply, {:ok, bet_ids}, state}
    end

    @spec handle_call({:market_get, market_id ::  integer}, GenServer.from(), any()) :: {:reply, {:ok, Betunfair.Market.t()}, any()} | {:reply, {:error, any()}, any()}
    def handle_call({:market_get, market_id}, _from, state) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:reply, {:error, "Market was not found"}, state}
        market ->
          {:reply, {:ok, market}, state}
      end
    end

    @spec handle_call({:market_pending_backs, market_id ::  integer}, GenServer.from(), any()) :: {{:reply, {:ok, Enumerable.t( integer)}, any()} | {:reply, {:error, any()}, any()}}
    def handle_call({:market_pending_backs, market_id}, _from, state) do
      # All back bets from market_id with remaining_stake > 0
      query = from b in Betunfair.Bet, where: b.market_id == ^market_id and b.type == "back" and b.remaining_stake > 0.0, order_by: [asc: :odds]
      bets = Betunfair.Repo.all(query)
      {:reply, {:ok, bets}, state}
    end

    @spec handle_call({:market_pending_lays, market_id ::  integer}, GenServer.from(), any()) :: {{:reply, {:ok, Enumerable.t( integer)}, any()} | {:reply, {:error, any()}, any()}}
    def handle_call({:market_pending_lays, market_id}, _from, state) do
      # All lay bets from market_id with remaining_stake > 0
      query = from b in Betunfair.Bet, where: b.market_id == ^market_id and b.type == "lay" and b.remaining_stake > 0.0, order_by: [desc: :odds]
      bets = Betunfair.Repo.all(query)
      {:reply, {:ok, bets}, state}
    end

    @spec handle_call({:market_cancel, market_id ::  integer, market :: Betunfair.Market.t()}, GenServer.from(), any()) :: {{:reply, :ok, any()} | {:reply, {:error, any()}, any()}}
    def handle_call({:market_cancel, market_id, market}, _from, state) do
      #Check if the market is active
      if market.status != "active" do
        {:reply, {:error, "Market is not active"}, state}
      else
        # Modify the status to cancelled and insert it in the database
        changeset = Betunfair.Market.changeset(market, %{status: "cancelled"})
        case Betunfair.Repo.update(changeset) do
          {:ok, _market} ->
            # Get all bets whose market_id is market_id and send the original_stake to the user
            query = from b in Betunfair.Bet, where: b.market_id == ^market_id
            bets = Betunfair.Repo.all(query)
            results = for bet <- bets do
              # Obtain the original stake and the user_id
              original_stake = bet.original_stake
              user_id = bet.user_id

              # Do a deposit to the user with the original stake
              case Betunfair.User.OperationsUser.user_deposit(user_id, original_stake) do
                :ok ->
                  {:ok}
                {:error, reason} ->
                  {:error, reason}
              end
            end
            if Enum.all?(results, &match?({:ok}, &1)) do
              {:reply, :ok, state}
            else
              {:reply, {:error, "Some deposits failed"}, state}
            end
          {:error, _changeset} ->
            {:reply, {:error, "Market could not be cancelled"}, state}
        end
      end

    end

    @spec handle_call({:market_freeze, market_id :: integer, market :: Betunfair.Market.t()}, GenServer.from(), any()) :: {{:reply, :ok, any()} | {:reply, {:error, any()}, any()}}
    def handle_call({:market_freeze, market_id, market}, _from, state) do
      if market.status != "active" do
        {:reply, {:error, "Market is not active"}, state}
      else
        changeset = Betunfair.Market.changeset(market, %{status: "frozen"})
        case Betunfair.Repo.update(changeset) do
          {:ok, _market} ->
            # Get all bets whose market_id is market_id and send the original_stake to the user
            query = from b in Betunfair.Bet, where: b.market_id == ^market_id and b.remaining_stake > 0.0
            bets = Betunfair.Repo.all(query)
            results = for bet <- bets do
              # Obtain the remaing stake and the user_id
              remaining_stake = bet.remaining_stake
              user_id = bet.user_id

              # Do a deposit to the user with the original stake
              case Betunfair.User.OperationsUser.user_deposit(user_id, remaining_stake) do
                :ok ->
                  {:ok}
                {:error, reason} ->
                  {:error, reason}
              end
            end
            if Enum.all?(results, &match?({:ok}, &1)) do
              {:reply, :ok, state}
            else
              {:reply, {:error, "Some deposits failed"}, state}
            end
          {:error, _changeset} ->
            {:reply, {:error, "Market could not be cancelled"}, state}
        end
      end
    end

    @spec handle_call({:market_settle, market_id ::  integer, market :: Betunfair.Market.t(), result :: boolean()}, GenServer.from(), any()) :: {{:reply, :ok, any()} | {:reply, {:error, any()}, any()}}
    def handle_call({:market_settle, market_id, market, result}, _from, state) do
      if market.status == "cancel" or market.status == "true" or market.status == "false" do
        {:reply, {:error, "Market can not settle"}, state}
      else
        changeset = Betunfair.Market.changeset(market, %{status: to_string(result)})
        case Betunfair.Repo.update(changeset) do
          {:ok, _market} ->
            # Get all bets whose market_id is market_id and send the original_stake to the user
            query = from m in Betunfair.Matched, join: b in Betunfair.Bet, on: b.id == m.id_bet_backed, where: b.market_id == ^market_id, select: m
            matcheds = Betunfair.Repo.all(query)

            results = for match <- matcheds do
              selected_stake =
                if (result == true and match.empty_stake == "back") or (result == false and match.empty_stake == "lay") do
                  match.balance_empty_stake
                else
                  match.balance_remain_stake
              end

              bet =
                if result == true do
                  #user_id = match.id_bet_layed
                  query2 = from b in Betunfair.Bet, where: b.id == ^match.id_bet_backed
                  Betunfair.Repo.one(query2)
                else
                  query2 = from b in Betunfair.Bet, where: b.id == ^match.id_bet_layed
                  Betunfair.Repo.one(query2)
                end

              # Do a deposit to the user with the original stake
              case Betunfair.User.OperationsUser.user_deposit(bet.user_id, selected_stake) do
                :ok ->
                  {:ok}
                {:error, reason} ->
                  {:error, reason}
              end
            end
            if Enum.all?(results, &match?({:ok}, &1)) do
              {:reply, :ok, state}
            else
              {:reply, {:error, "Some deposits failed"}, state}
            end
          {:error, _changeset} ->
            {:reply, {:error, "Market could not be settled"}, state}
        end
      end
      #Obtengo todos los match del market. Para ello, consigo la lista de bets matcheadas y veo su market_id
    end

    @doc """
      This function changes the status of the market to cancelled
    """
    @spec market_cancel(market_id ::  integer) :: {:ok| {:error, any()}}
    def market_cancel(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        market ->
          case GenServer.call(:"market_#{market_id}", {:market_cancel, market_id, market}) do
            :ok ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function changes the status of the market to frozen
    """
    @spec market_freeze(market_id ::  integer) :: {:ok| {:error, any()}}
    def market_freeze(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        market ->
          case GenServer.call(:"market_#{market_id}", {:market_freeze, market_id, market}) do
            :ok ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function changes the status of the market to settled, and true of false, depending on the result
      True indicates that the back bet won, and false indicates that the lay bet won.
    """
    @spec market_settle(market_id ::  integer, result :: boolean()) :: {:ok| {:error, any()}}
    def market_settle(market_id, result) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        market ->
          if (market.status != "frozen") do
            case GenServer.call(:"market_#{market_id}", {:market_freeze, market_id, market}) do
              :ok ->
                case GenServer.call(:"market_#{market_id}", {:market_settle, market_id, market, result}) do
                  :ok ->
                    :ok
                  {:error, reason} ->
                    {:error, reason}
                end
              {:error, reason} ->
                {:error, reason}
            end
          else
            case GenServer.call(:"market_#{market_id}", {:market_settle, market_id, market, result}) do
              :ok ->
                :ok
              {:error, reason} ->
                {:error, reason}
            end
        end

      end
    end

    @doc """
      This function returns the list of bets of the market
    """
    @spec market_bets(market_id ::  integer) :: { {:ok, Enumerable.t({integer(),  integer})} | {:error, any()}}
    def market_bets(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        market ->
          case GenServer.call(:"market_#{market_id}", {:market_bets, market_id, market}) do
            {:ok, bet_ids} ->
              {:ok, bet_ids}
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function returns the information of the market
    """
    @spec market_get(market_id ::  integer) :: { {:ok, %{name: String.t(), description: String.t(), status: atom()}} | {:error, any()}}
    def market_get(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        _market ->
          case GenServer.call(:"market_#{market_id}", {:market_get, market_id}) do
            {:ok, market} ->
              if(market.status == "true") do
                {:ok, %{
                  name: market.name,
                  description: market.description,
                  status: {:settled, true}
                }}
              else
                if (market.status == "false") do
                  {:ok, %{
                    name: market.name,
                    description: market.description,
                    status: {:settled, false}
                  }}
                else
                  {:ok, %{
                    name: market.name,
                    description: market.description,
                    status: String.to_atom(market.status)
                  }}
                end
              end
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function matches the bets of the market. It applies the algorithm to match the bets.
    """
    @spec market_match(market_id ::  integer) :: { :ok | {:error, any()}}
    def market_match(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        _market ->
          case GenServer.call(:"match_#{market_id}", {:market_match, market_id}) do
            {:ok} ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function returns the list of non entirely matched back bets of the market.
      A bet is entirely matched if its remaining stake is 0.
    """
    @spec market_pending_backs(market_id ::  integer) :: { {:ok, Enumerable.t({float(),  integer})} | {:error, any()}}
    def market_pending_backs(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        _market ->
          case GenServer.call(:"market_#{market_id}", {:market_pending_backs, market_id}) do
            {:ok, bet_ids} ->
              {:ok, Enum.map(bet_ids, &({&1.odds,&1.id}))}
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function returns the list of non entirely matched lay bets of the market.
      A bet is entirely matched if its remaining stake is 0.
    """
    @spec market_pending_lays(market_id ::  integer) :: { {:ok, Enumerable.t({float(),  integer})} | {:error, any()}}
    def market_pending_lays(market_id) do
      case Betunfair.Repo.get(Betunfair.Market, market_id) do
        nil ->
          {:error, "Market was not found"}
        _market ->
          case GenServer.call(:"market_#{market_id}", {:market_pending_lays, market_id}) do
            {:ok, bet_ids} ->
              {:ok, Enum.map(bet_ids, &({&1.odds,&1.id}))}
            {:error, reason} ->
              {:error, reason}
          end
      end
    end


  end

  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :description, :status])
  end
end
