defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset
  require Logger


  schema "users" do
    field :balance, :float
    field :id_users, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorUser do
    use Supervisor

    @moduledoc """
      This supervisor will supervise the user manager and the user operations processes.
      It is created when the applications starts.
    """

    @doc """
      Starts the supervisor for the user manager. Establish its name as :user_supervisor.
    """
    @spec start_link(any) :: {:ok, Supervisor.t()} | {:error, any}
    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: :user_supervisor)
    end

    @doc """
      Initializes the supervisor with the children to be supervised.
    """
    @spec init(any) :: Supervisor.Spec.t()
    def init(_) do
      children = [
        {Betunfair.User.GestorUser, []}
      ]
      state = Supervisor.init(children, strategy: :one_for_one)
      Task.start(fn -> load_user() end)
      state
    end

    @spec load_user() :: :ok
    defp load_user() do
      users = Betunfair.Repo.all(Betunfair.User)
      for user <- users do
        createProcessUser(user)
        Process.sleep(100) # Adds 100 ms delay between process creation sothey do not select the same PID
      end
      :ok
    end

    @spec createProcessUser(Betunfair.User.t) :: :ok
    defp createProcessUser(user) do
      child_name = :"user_#{user.id}"
      if Process.whereis(child_name) == nil do
        Supervisor.start_child(:user_supervisor, {Betunfair.User.OperationsUser, {:args, child_name, user.id}})
      end
      :ok
    end

  end

  defmodule GestorUser do
    use GenServer
    @moduledoc """
      This process will be supervised by the user supervisor.
      The user manager is a GenServer that receives the user creation requests and creates the user and the process.
      The process created will be supervised by the user supervisor.
    """

    @doc """
      Starts the GenServer for the user manager. Establish its name as :user_gestor.
    """
    @spec start_link(Enumerable.t()) :: {:ok, GenServer.t()} | {:error, any}
    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :user_gestor)
    end

    @doc """
      Initializes the GenServer with the arguments.
    """
    @spec init(any) :: {:ok, any}
    def init(args) do
      {:ok, args}
    end

    @spec handle_call({:user_create, id :: String.t(), name :: String.t()}, GenServer.t, any) :: {:reply, {:ok, Integer.t()}, any} | {:reply, {:error, String.t()}, any}
    def handle_call({:user_create, id, name}, _from, state) do
      case Betunfair.User.GestorUser.add_child_operation(name, id) do
        {:ok, user_id} ->
          {:reply, {:ok, user_id}, state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end

    end

    @doc """
      This function is called when a new user is created. If there is no user with that id in the database,
      it creates a new user and a new process for that user, and adds the user into the database.
      If the user already exists, it returns an error message. This new process will be supervised by the
      user supervisor.
    """
    @spec user_create(id :: String.t(), name :: String.t()) :: {:ok, Integer.t()} | {:error, String.t()}
    def user_create(id , name) do
      case Betunfair.Repo.get_by(Betunfair.User, id_users: id) do
        nil ->
          GenServer.call(:user_gestor, {:user_create, id, name})
        _user ->
          {:error, "A user with the same ID already exists"}
      end
    end

    @spec add_child_operation(name :: String.t(), id :: String.t()) :: {:ok, Integer.t()} | {:error, String.t()}
    defp add_child_operation(name, id) do
      case insert_user(id, name) do
        {:ok, user} ->
          child_name = :"user_#{user.id}" #nombre del hijo
          Supervisor.start_child(:user_supervisor, {Betunfair.User.OperationsUser, {:args, child_name, user.id}})
          {:ok, user.id}
        {:error, reason} ->
          {:error, reason}
      end
    end

    @spec insert_user(id :: String.t(), name :: String.t()) :: {:ok, Betunfair.User.t()} | {:error, String.t()}
    defp insert_user(id, name) do
      changeset = Betunfair.User.changeset(%Betunfair.User{}, %{id_users: id, name: name, balance: 0})


      case Betunfair.Repo.insert(changeset) do
        {:ok, user} ->
          {:ok, user}
        {:error, changeset} ->
          {:error, "User couldn't be inserted. The reason: #{inspect(changeset.errors)}"}
      end
    end
  end


  defmodule OperationsUser do
    use GenServer
    import Ecto.Query, only: [from: 2]

    @moduledoc """
      This process will be supervised by the user supervisor.
      The user operations process is a GenServer that receives the user operations requests and processes them.
    """

    @doc """
      Defines the child specification for the user operations process.
    """
    @spec child_spec({:args, child_name :: String.t(), user_id :: Integer.t()}) :: Supervisor.Spec.t()
    def child_spec({:args, child_name, user_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [{:args, child_name, user_id}]},
        type: :worker,
        restart: :permanent,
        shutdown: 5000
      }

    end

    @doc """
      Starts the GenServer for user operations.
    """
    @spec start_link({:args, name :: String.t(), user_id :: Integer.t()}) :: {:ok, GenServer.t()} | {:error, any}
    def start_link({:args, name, user_id}) do
      GenServer.start_link(__MODULE__,{user_id} , name: name)
    end

    @doc """
      Initializes the GenServer with the user ID.
    """
    @spec init(user_id :: Integer.t()) :: {:ok, Integer.t()} | {:error, String.t()}
    def init(user_id) do
      {:ok, user_id}
    end

    @spec handle_call({:deposit, amount :: Float.t(), id :: Integer.t(), user :: Betunfair.User.t()}, GenServer.t, any) :: {:reply, {:ok, Float.t()}, any} | {:reply, {:error, String.t()}, any}
    def handle_call({:deposit, amount, id, user}, _from, user_id) do
      case deposit(id, amount, user) do
        {:ok, new_balance} ->
          {:reply, {:ok, new_balance}, new_balance}
        {:error, reason} ->
          {:reply, {:error, reason}, user_id}
      end
    end

    @spec deposit(user_id :: Integer.t(), amount :: Float.t(), user :: Betunfair.User.t()) :: {:ok, Float.t()} | {:error, String.t()}
    defp deposit(_user_id, amount, user) do
      if amount <= 0 do
        {:error, "The amount you need to deposit must be greater than 0"}
      else
        new_balance = user.balance + amount
        changeset = Betunfair.User.changeset(user, %{balance: new_balance})
        case Betunfair.Repo.update(changeset) do
          {:ok, _user} ->
            {:ok, new_balance}
          {:error, changeset} ->
            {:error, "User couldn't be updated. The reason: #{inspect(changeset.errors)}"}
        end

      end
    end

    @spec handle_call({:withdraw, amount :: Float.t(), id :: Integer.t(), user :: Betunfair.User.t()}, GenServer.t, any) :: {:reply, {:ok, Float.t()}, any} | {:reply, {:error, String.t()}, any}
    def handle_call({:withdraw, amount, id, user}, _from, user_id) do
      case withdraw(id, amount, user) do
        {:ok, new_balance} ->
          {:reply, {:ok, new_balance}, new_balance}
        {:error, reason} ->
          {:reply, {:error, reason}, user_id}
      end
    end

    @spec withdraw(user_id :: Integer.t(), amount :: Float.t(), user :: Betunfair.User.t()) :: {:ok, Float.t()} | {:error, String.t()}
    defp withdraw(_user_id, amount, user) do
      if amount <= 0 do
        {:error, "The amount you need to withdraw must be greater than 0"}
      else
        new_balance = user.balance - amount
        if new_balance < 0 do
          {:error, "You don't have enough balance to withdraw that amount"}
        else
          changeset = Betunfair.User.changeset(user, %{balance: new_balance})
          case Betunfair.Repo.update(changeset) do
            {:ok, _user} ->
              {:ok, new_balance}
            {:error, changeset} ->
              {:error, "User couldn't be updated. The reason: #{inspect(changeset.errors)}"}
          end
        end # if new_balance < 0
      end # if amount <= 0
    end

    @spec handle_call({:get, id :: Integer.t()}, GenServer.t, any) :: {:reply, Betunfair.User.t(), any} | {:reply, {:error, String.t()}, any}
    def handle_call({:get, id}, _from, user_id) do

      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:reply, {:error, "User was not found"}, user_id}
        user ->
          {:reply, user, user_id}
      end
    end

    @spec handle_call({:bet, id :: Integer.t()}, GenServer.t, any) :: {:reply, {:ok, [Integer.t()]}, any} | {:reply, {:error, String.t()}, any}
    def handle_call({:bet, id}, _from, state) do
      query = from b in Betunfair.Bet, where: b.user_id == ^id
      bets = Betunfair.Repo.all(query)
      #crear un Enumerable.t con los id de las bets
      bet_ids = Enum.map(bets, &(&1.id))
      {:reply, {:ok, bet_ids}, state}
    end



    #--- Client functions ---
    @doc """
      This function is called when a user wants to deposit money into his account.
      It checks if the user exists, and if it does, it adds the amount to the user's balance,
      if the amount he wants to place is valid.
    """
    @spec user_deposit(id :: Integer.t(), amount :: Float.t()) :: :ok | {:error, String.t()}
    def user_deposit(id, amount) do
      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:error, "User was not found"}
        user ->
          case GenServer.call(:"user_#{id}", {:deposit, amount, id, user}) do
            {:ok, _new_balance} ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function is called when a user wants to withdraw money from his account.
      It checks if the user exists, and if it does, it subtracts the amount from the user's balance,
      if the amount he wants to withdraw is valid.
    """
    @spec user_withdraw(id :: Integer.t(), amount :: Float.t()) :: :ok | {:error, String.t()}
    def user_withdraw(id, amount) do
      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:error, "User was not found"}
        user ->
          case GenServer.call(:"user_#{id}", {:withdraw, amount, id, user}) do
            {:ok, _new_balance} ->
              :ok
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

    @doc """
      This function is called when a user wants to get his information.
      It checks if the user exists, and if it does, it returns the user's information.
    """
    @spec user_get(id :: Integer.t()) :: {:ok, %{name: String.t(), id: Integer.t(), balance: Float.t()}} | {:error, String.t()}
    def user_get(id) do
      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:error, "User was not found"}
        _user ->
          case GenServer.call(:"user_#{id}", {:get, id}) do
            {:error, reason} ->
              {:error, reason}
            user ->
              {:ok, %{
                name: user.name,
                id: user.id_users,
                balance: user.balance
              }}

          end
      end
    end

    @doc """
      This function is called when a user wants to get his bets.
      It checks if the user exists, and if it does, it returns the user's bets' ids.
    """
    @spec user_bets(id :: Integer.t()) :: {:ok, Enumerable.t(Integer.t())} | {:error, String.t()}
    def user_bets(id) do
      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:error, "User was not found"}
        _user ->
          case GenServer.call(:"user_#{id}", {:bet, id}) do
            {:ok, bet_ids} ->
              bet_ids
            {:error, reason} ->
              {:error, reason}
          end
      end
    end

  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id_users, :balance, :name])
    |> validate_required([:id_users, :balance, :name])
    |> unique_constraint(:id_users)
  end
end
