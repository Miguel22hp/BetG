defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Betunfair.Repo
  require Logger

  schema "users" do
    field :balance, :integer
    field :id_users, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorUser do
    use Supervisor
    require Logger

    def start_link(_) do
      Supervisor.start_link(_MODULE_, [], name: :user_supervisor)
    end

    def init(_) do
      children = []

      state = Supervisor.init(children, strategy: :one_for_one)
      Task.start(fn -> load_user() end)
      state
    end

    def user_create(id , name) do
      case Betunfair.Repo.get_by(Betunfair.User, id_users: id) do
        nil ->
          add_child_operation(name, id)
        _user ->
          {:error, "Ya existe un usuario con el mismo ID"}
      end
    end

    def add_child_operation(name, id) do
      case insert_user(id, name) do
        {:ok, user} ->
          child_name = :"user_#{user.id}"
          case Supervisor.start_child(:user_supervisor, {Betunfair.User.OperationsUser, {:args, child_name, user.id}}) do
            {:ok, _child} ->
              Logger.info("Proceso hijo #{child_name} creado correctamente")
              {:ok, user.id}
            {:error, reason} ->
              Logger.error("Error al crear el proceso hijo #{child_name}: #{inspect(reason)}")
              {:error, reason}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end

    def insert_user(id, name) do
      changeset = Betunfair.User.changeset(%Betunfair.User{}, %{id_users: id, name: name, balance: 0})

      case Betunfair.Repo.insert(changeset) do
        {:ok, user} ->
          {:ok, user}
        {:error, changeset} ->
          {:error, "No se pudo insertar el usuario: #{inspect(changeset.errors)}"}
      end
    end

    def load_user() do
      users = Betunfair.Repo.all(Betunfair.User)
      for user <- users do
        createProcessUser(user)
      end
    end

    def createProcessUser(user) do
      child_name = :"user_#{user.id}"
      Logger.info("Intentando crear proceso #{child_name}")
      if Process.whereis(child_name) == nil do
        Logger.info("Proceso #{child_name} no existe, creando...")
        case Supervisor.start_child(:user_supervisor, %{
          id: child_name,
          start: {Betunfair.User.OperationsUser, :start_link, [{:args, child_name, user.id}]}
        }) do
          {:ok, _child} ->
            Logger.info("Proceso #{child_name} creado")
          {:error, reason} ->
            Logger.error("Error al crear el proceso #{child_name}: #{inspect(reason)}")
        end
      else
        Logger.info("Proceso #{child_name} ya existe")
      end
    end
  end

  defmodule OperationsUser do
    use GenServer
    require Logger

    def start_link({:args, name, user_id}) do
      Logger.info("Creando proceso en OperationsUser #{name}")
      GenServer.start_link(_MODULE_, {user_id}, name: name)
    end

    def init(user_id) do
      {:ok, user_id}
    end

    def handle_call({:deposit, amount, id}, _from, user_id) do
      case deposit(id, amount) do
        {:ok, new_balance} ->
          {:reply, {:ok, new_balance}, new_balance}
        {:error, reason} ->
          {:reply, {:error, reason}, user_id}
      end
    end

    def deposit(user_id, amount) do
      if amount <= 0 do
        {:error, "La cantidad a depositar debe ser mayor a 0"}
      else
        case Betunfair.Repo.get(Betunfair.User, user_id) do
          nil ->
            {:error, "No se encontró el usuario"}
          user ->
            new_balance = user.balance + amount
            changeset = Betunfair.User.changeset(user, %{balance: new_balance})
            case Betunfair.Repo.update(changeset) do
              {:ok, _user} ->
                {:ok, new_balance}
              {:error, changeset} ->
                {:error, "No se pudo actualizar el usuario: #{inspect(changeset.errors)}"}
            end
        end
      end
    end

    def handle_call({:withdraw, amount, id}, _from, user_id) do
      case withdraw(id, amount) do
        {:ok, new_balance} ->
          {:reply, {:ok, new_balance}, new_balance}
        {:error, reason} ->
          {:reply, {:error, reason}, user_id}
      end
    end

    def withdraw(user_id, amount) do
      if amount <= 0 do
        {:error, "La cantidad a retirar debe ser mayor a 0"}
      else
        case Betunfair.Repo.get(Betunfair.User, user_id) do
          nil ->
            {:error, "No se encontró el usuario"}
          user ->
            new_balance = user.balance - amount
            if new_balance < 0 do
              {:error, "No tienes suficiente saldo para retirar esa cantidad"}
            else
              changeset = Betunfair.User.changeset(user, %{balance: new_balance})
              case Betunfair.Repo.update(changeset) do
                {:ok, _user} ->
                  {:ok, new_balance}
                {:error, changeset} ->
                  {:error, "No se pudo actualizar el usuario: #{inspect(changeset.errors)}"}
              end
            end
        end
      end
    end

    def handle_call({:get, id}, _from, user_id) do
      case Betunfair.Repo.get(Betunfair.User, id) do
        nil ->
          {:reply, {:error, "No se encontró el usuario"}, user_id}
        user ->
          {:reply, user, user_id}
      end
    end

    #--- Client functions ---
    def user_deposit(id, amount) do
      case GenServer.call(:"user_#{id}", {:deposit, amount, id}) do
        {:ok, new_balance} ->
          {:ok}
        {:error, reason} ->
          {:error, reason}
      end
    end

    def user_withdraw(id, amount) do
      Logger.info(:"user_#{id}")
      case GenServer.call(:"user_#{id}", {:withdraw, amount, id}) do
        {:ok, new_balance} ->
          {:ok}
        {:error, reason} ->
          {:error, reason}
      end
    end

    def user_get(id) do
      case GenServer.call(:"user_#{id}", {:get, id}) do
        user ->
          {:ok, %{
            name: user.name,
            id: user.id_users,
            balance: user.balance
          }}
        {:error, reason} ->
          {:error, reason}
      end
    end

    def user_bets(id) do
      GenServer.call(:"user_#{id}", {:bet, id})
    end
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id_users, :balance, :name])
    |> validate_required([:id_users, :balance, :name])
    |> unique_constraint(:id_users)
  end

  # API to add funds to a user's account
  def add_funds(user_id, amount) when is_integer(amount) and amount > 0 do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      changeset = changeset(user, %{balance: user.balance + amount})
      Repo.update!(changeset)
    end)
  end

  # API to remove funds from a user's account
  def remove_funds(user_id, amount) when is_integer(amount) and amount > 0 do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      if user.balance >= amount do
        changeset = changeset(user, %{balance: user.balance - amount})
        Repo.update!(changeset)
      else
        raise "Insufficient funds"
      end
    end)
  end

  # API to fetch user info
  def get_user_info(user_id) do
    Repo.get_by(User, user_id)
  end

  # API to update user's name
  def update_user_name(user_id, new_name) when is_binary(new_name) do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      changeset = changeset(user, %{name: new_name})
      Repo.update!(changeset)
    end)
  end
end
