defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :balance, :integer
    field :id_users, :string
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorUser do
    use Supervisor

    def start_link() do
      Supervisor.start_link(__MODULE__, [], name: :user_supervisor)
    end

    def init(_) do
      Supervisor.init([], strategy: :one_for_one)
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
          child_name = :"user_#{user.id}"
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
    def start_link({:args, name, user_id}) do
      GenServer.start_link(__MODULE__,{user_id} , name: name)
    end

    def init(user_id) do
      {:ok, user_id}
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
