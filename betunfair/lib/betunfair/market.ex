defmodule Betunfair.Market do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query


  schema "markets" do
    field :description, :string
    field :name, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  defmodule SupervisorMarket do
    use Supervisor

    def start_link() do
      Supervisor.start_link(__MODULE__, [], name: :market_supervisor)
    end

    def init(_) do
      children = [
        {Betunfair.Market.GestorMarket, {:args}}
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end



  end

  defmodule GestorMarket do
    use GenServer

    def start_link({:args}) do
      GenServer.start_link(__MODULE__, [], name: :gestor_market)
    end

    def init(args) do
      IO.puts("Gestor de mercado creado con nombre")
      {:ok, args}
    end

    def handle_call({:market_create, name, description}, _from, state) do
      case Betunfair.Repo.get_by(Betunfair.Market, name: name) do
        nil ->
          # No hay ningún mercado con el mismo nombre, puedes proceder a crear el mercado
          # Aquí iría la lógica para crear el mercado
          case add_child_operation(name, description) do
            {:ok, market_id} ->
              {:reply, {:ok, market_id}, state}
            {:error, reason, texto} ->
              {:reply, {:error, reason, texto}, state}
          end
        _market ->
          # Ya existe un mercado con el mismo nombre, maneja este caso según tus necesidades
          # Por ejemplo, podrías devolver un error o lanzar una excepción
          {:reply, {:error, "Ya existe un mercado con el mismo nombre"}, state}
      end
    end

    def add_child_operation(name, description) do
      case insert_market(name, description) do
        {:ok, market} ->
          child_name = :"market_#{market.id}" #nombre del hijo
          IO.puts("Nombre del hijo: #{child_name}")
          child_spec = {Betunfair.Market.OperationsMarket, {:args, child_name, market.id}}
          case Supervisor.start_child(:market_supervisor, child_spec) do
            {:ok, _pid} ->
              {:ok, market.id}
            {:error, reason} ->
              {:error, reason, "ERROR AL CREAR EL HIJO"}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end

    def insert_market(name, description) do
      changeset = Betunfair.Market.changeset(%Betunfair.Market{}, %{name: name, description: description, status: "active"})
      case Betunfair.Repo.insert(changeset) do
        {:ok, market} ->
          {:ok, market}
        {:error, changeset} ->
          {:error, "No se pudo insertar el mercado: #{inspect(changeset.errors)}"}
      end
    end


    def market_create(name, description) do
      case GenServer.call(:gestor_market, {:market_create, name, description}) do
        {:ok, market_id} ->
          {:ok, market_id}
        {:error, reason, texto} ->
          {:error, reason, texto}
      end
    end

  end



  defmodule OperationsMarket do
    use GenServer

    def start_link({:args, name, id}) do
      GenServer.start_link(__MODULE__, {:args, name, id}, name: name)
    end

    def init({:args, name, id}) do
      IO.puts("Market #{name} created with ID: #{id}")
      {:ok, %{name: name, id: id}}
    end


  end


  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :description, :status])
  end
end
