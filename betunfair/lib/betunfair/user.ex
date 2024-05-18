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

    def start_link(_) do
      Supervisor.start_link(__MODULE__, [], name: :user_supervisor)
    end

    def init(_) do

      children = [
        {Betunfair.User.GestorUser, []}
      ]
      state = Supervisor.init(children, strategy: :one_for_one)
      Task.start(fn -> load_user() end)
      state
    end

    def load_user() do
      users = Betunfair.Repo.all(Betunfair.User)
      #Enum.each(users, &createProcessUser/1)
      for user <- users do
        createProcessUser(user)
        Process.sleep(100) # Adds 100 ms delay between process creation sothey do not select the same PID
      end
    end

    def createProcessUser(user) do
      child_name = :"user_#{user.id}"
      IO.puts("Creando proceso #{child_name}")
      if Process.whereis(child_name) == nil do
        IO.puts("Dentro del if #{child_name}")
        Supervisor.start_child(:user_supervisor, {Betunfair.User.OperationsUser, {:args, child_name, user.id}})
      end
    end

  end

  defmodule GestorUser do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :user_gestor)
    end

    def init(args) do
      IO.puts("Gestor de usuario creado con nombre")
      {:ok, args}
    end

    def handle_call({:user_create, id, name}, _from, state) do
      case Betunfair.User.SupervisorUser.user_create(id, name) do
        {:ok, user_id} ->
          {:reply, {:ok, user_id}, state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end

    end

    def user_create(id , name) do
      case Betunfair.Repo.get_by(Betunfair.User, id_users: id) do
        nil ->
          # No hay ningún usuario con el mismo ID, puedes proceder a crear el usuario
          # Aquí iría la lógica para crear el usuario
          add_child_operation(name, id)
        _user ->
          # Ya existe un usuario con el mismo ID, maneja este caso según tus necesidades
          # Por ejemplo, podrías devolver un error o lanzar una excepción
          {:error, "Ya existe un usuario con el mismo ID"}
      end
    end

    def add_child_operation(name, id) do
      case insert_user(id, name) do
        {:ok, user} ->
          child_name = :"user_#{user.id}" #nombre del hijo
          Supervisor.start_child(:user_supervisor, {Betunfair.User.OperationsUser, {:args, child_name, user.id}})
          {:ok, user.id}
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
  end


  defmodule OperationsUser do
    use GenServer

    def child_spec({:args, child_name, user_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [{:args, child_name, user_id}]},
        type: :worker,
        restart: :permanent,
        shutdown: 5000
      }

    end


    def start_link({:args, name, user_id}) do
      IO.puts("Creando proceso en  OperationsUser #{name}")
      GenServer.start_link(__MODULE__,{user_id} , name: name)
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
      IO.puts("Depositando #{amount} al usuario #{user_id}")
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
          end # if new_balance < 0
        end # case Betunfair.Repo.get(Betunfair.User, user_id)
      end # if amount <= 0
    end # function withdraw

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
      IO.puts(:"user_#{id}")
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
end
