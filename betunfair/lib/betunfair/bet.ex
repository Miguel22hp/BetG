defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger

  schema "bets" do
    field :odds, :float
    field :original_stake, :float
    field :remaining_stake, :float
    field :type, :string
    field :status, :string
    #adding the user_id and market_id as a FK on Ecto Schema
    belongs_to :user, Betunfair.User
    belongs_to :market, Betunfair.Market

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
      state = Supervisor.init(children, strategy: :one_for_one)
      Task.start(fn -> load_bets() end) #load every bet from EctoDB as a process
      state
    end

    defp load_bets() do
      bets = Betunfair.Repo.all(Betunfair.Bet)
      for bet <- bets do
        createProcessBet(bet)
        Process.sleep(100) # Adds 100 ms delay between process creation sothey do not select the same PID
      end
    end

    defp createProcessBet(bet) do
      child_name = :"bet_#{bet.id}"
      child_spec = Betunfair.Bet.OperationsBet.child_spec({:args, bet.id, child_name})
      Supervisor.start_child(:bet_supervisor, child_spec)
      end

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
          {:reply, {:error, reason}, state}
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
          create_bet(bet, market_id, state)
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end

    @spec bet_back(user_id :: integer, market_id :: integer, stake :: integer, odds :: integer) :: {:ok, integer}
    def bet_back(user_id, market_id, stake, odds) do
      process_name = :"gestor_bet_market_#{market_id}"
      GenServer.call(process_name, {:back_bet, user_id, market_id, stake, odds})
    end

    def handle_call({:lay_bet, user_id, market_id, stake, odds}, _from, state) do
      case insert_bet(user_id, market_id, stake, odds, "lay") do
        {:ok, bet} ->
          create_bet(bet, market_id, state)
        {:error, reason} ->
          {:reply, {:error, reason}, state}
        end
    end

    defp create_bet(bet, market_id, state) do
      child_name = :"bet_#{bet.id}"
      child_spec = Betunfair.Bet.OperationsBet.child_spec({:args, bet.id, child_name})
      process_name = :"supervisor_bet_market_#{market_id}"
      case Supervisor.start_child(process_name, child_spec) do
        {:ok, _pid} ->
          {:reply, {:ok, bet.id}, state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end

    @spec bet_lay(user_id :: integer, market_id :: integer, stake :: float, odds :: float) :: {:ok, integer}
    def bet_lay(user_id, market_id, stake, odds) do
      process_name = :"gestor_bet_market_#{market_id}"
      GenServer.call(process_name, {:lay_bet, user_id, market_id, stake, odds})
    end

    #You manage the operations for creating OperationsBet processes. They are created when a bet is created.
    defp insert_bet(user_id, market_id, stake, odds, type) do
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
                {:error, "market with id #{market_id} doesn't exist"}
              market ->
                if market.status == "active" do
                  changeset = Betunfair.User.changeset(user, %{balance: user.balance - stake})
                  case Betunfair.Repo.update(changeset) do
                    {:ok, user} ->
                      {:ok, user}
                    {:error, changeset} ->
                      {:error, "Couldn't modify user balance for user #{user_id}: #{inspect(changeset.errors)}"}
                    end
                  changeset = Betunfair.Bet.changeset(%Betunfair.Bet{}, %{user_id: user_id, market_id: market_id, original_stake: stake, remaining_stake: stake, odds: odds, type: type, status: "active"})
                  case Betunfair.Repo.insert(changeset) do
                    {:ok, bet} ->
                      {:ok, bet}
                    {:error, changeset} ->
                      {:error, "Couldn't create the bet for user #{user_id}: #{inspect(changeset.errors)}"}
                  end
                else
                  {:error, "cannot insert bet for market #{market.id}: is not active"}
                end
              end
          end
        end
    end

  end

  defmodule OperationsBet do
    import Ecto.Query, only: [from: 2]
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

    def handle_call({:bet_get, bet_id}, _from, state) do
      case Betunfair.Repo.get(Betunfair.Bet, bet_id) do
        nil ->
          {:error, "Could not find the bet with id #{bet_id}", state}
        bet ->
          {:reply, {:ok, bet}, state}
      end
    end

    defp get_matched_bets(bet) do
      query = from m in Betunfair.Matched,
              where: m.id_bet_backed == ^bet.id or m.id_bet_layed == ^bet.id,
              select: {m.id_bet_backed, m.id_bet_layed}
      Betunfair.Repo.all(query)
      |> Enum.flat_map(fn {backed_id, layed_id} -> [backed_id, layed_id] end)
      |> Enum.reject(&(&1 == bet.id))
    end

    @spec bet_get(id :: integer) :: {:ok, %{bet_type: :back | :lay,
                                            market_id: integer,
                                            user_id: integer,
                                            odds: integer,
                                            original_stake: integer,
                                            remaining_stake: integer,
                                            matched_bets: [integer],
                                            status: :active |
                                                    :cancelled |
                                                    :market_cancelled |
                                                    {:market_settled, boolean}
                                            }
                                      }
    def bet_get(id) do
      # You manage the operations for getting a bet.
      case Betunfair.Repo.get(Betunfair.Bet, id) do
        nil ->
          {:error, "Could not find the bet with id #{id}"}
        _bet ->
          case GenServer.call(:"bet_#{id}", {:bet_get, id}) do
            {:ok, bet} ->
              case bet.status do
                "active" ->
                  case Betunfair.Repo.get(Betunfair.Market, bet.market_id) do
                    nil ->
                      {:error, "market #{bet.market_id} doesn't exist"}
                    market ->
                      case market.status do
                        "cancelled" ->
                          {:ok, %{
                            bet_type: bet.type,
                            market_id: bet.market_id,
                            user_id: bet.user_id,
                            odds: bet.odds,
                            original_stake: bet.original_stake,
                            remaining_stake: bet.remaining_stake,
                            matched_bets: get_matched_bets(bet),
                            status: :market_cancelled
                          }}
                        "true" ->
                          {:ok, %{
                            bet_type: bet.type,
                            market_id: bet.market_id,
                            user_id: bet.user_id,
                            odds: bet.odds,
                            original_stake: bet.original_stake,
                            remaining_stake: bet.remaining_stake,
                            matched_bets: get_matched_bets(bet),
                            status: {:market_settled, true}
                          }}
                          "false" ->
                            {:ok, %{
                              bet_type: bet.type,
                              market_id: bet.market_id,
                              user_id: bet.user_id,
                              odds: bet.odds,
                              original_stake: bet.original_stake,
                              remaining_stake: bet.remaining_stake,
                              matched_bets: get_matched_bets(bet),
                              status: {:market_settled, false}
                            }}
                          _  ->
                            {:ok, %{
                              bet_type: bet.type,
                              market_id: bet.market_id,
                              user_id: bet.user_id,
                              odds: bet.odds,
                              original_stake: bet.original_stake,
                              remaining_stake: bet.remaining_stake,
                              matched_bets: get_matched_bets(bet),
                              status: String.to_atom(bet.status)
                            }}
                      end
                  end
                "cancelled" ->
                  {:ok, %{
                    bet_type: bet.type,
                    market_id: bet.market_id,
                    user_id: bet.user_id,
                    odds: bet.odds,
                    original_stake: bet.original_stake,
                    remaining_stake: bet.remaining_stake,
                    matched_bets: get_matched_bets(bet),
                    status: String.to_atom(bet.status)
                  }}
              end
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    def handle_call({:bet_cancel, bet_id}, _from, state) do
      case Betunfair.Repo.get(Betunfair.Bet, bet_id) do
        nil ->
          {:error, "Could not find the bet with id #{bet_id}", state}
        bet ->
          case Betunfair.Repo.get(Betunfair.User, bet.user_id) do
            nil ->
              {:error, "Could not find the user #{bet.user_id} with bet #{bet.id}"}
            user ->
              changeset = Betunfair.User.changeset(user, %{balance: user.balance + bet.remaining_stake})
              case Betunfair.Repo.update(changeset) do
                {:error, changeset} ->
                  {:error, "Could not update the bet with id #{bet_id}; #{inspect(changeset.errors)}", state}
                _ ->
                  changeset = Betunfair.Bet.changeset(bet, %{remaining_stake: 0, status: "cancelled"})
                  case Betunfair.Repo.update(changeset) do
                    {:ok, bet} ->
                      {:reply, {:ok, bet}, state}
                    {:error, changeset} ->
                      {:error, "Could not update the bet with id #{bet_id}; #{inspect(changeset.errors)}", state}
                  end
              end
          end
        end
    end

    @spec bet_cancel(id :: integer):: :ok
    def bet_cancel(id) do
      #cancels the parts of a bet that has not been matched yet (remaining_stake).
      case Betunfair.Repo.get(Betunfair.Bet, id) do
        nil ->
          {:error, "Could not find the bet with id #{id}"}
        _bet ->
          case GenServer.call(:"bet_#{id}", {:bet_cancel, id}) do
            {:ok, _bets} ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
        end
    end

  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:user_id, :market_id, :odds, :type, :original_stake, :remaining_stake, :status])
    |> validate_required([:user_id, :market_id, :odds, :type, :original_stake, :remaining_stake])
    |> assoc_constraint(:user)
    |> assoc_constraint(:market)
  end

end
