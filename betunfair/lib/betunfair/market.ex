defmodule Betunfair.Market do
  use Ecto.Schema
  import Ecto.Changeset

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
        {Betunfair.Market.GestorMarket, []}
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end

    def add_child_operation(name, description) do
      case insert_market(name, description) do
        {:ok, market} ->
          child_name = :"market_#{market.id}" #nombre del hijo
          IO.puts("Nombre del hijo: #{child_name}")
          child_spec = Betunfair.Market.OperationsMarket.child_spec({:args, child_name, market.id})
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

  end

  defmodule GestorMarket do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, [], name: :market_gestor)
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
          case Betunfair.Market.SupervisorMarket.add_child_operation(name, description) do
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

    def handle_call({:market_list}, _from, state) do
      markets = Betunfair.Repo.all(Betunfair.Market)
      case markets do
        [] ->
          {:reply, {:error, "No hay mercados"}, state}
        _markets ->
          market_ids = Enum.map(markets, &(&1.id))
          {:reply, {:ok, market_ids}, state}
      end
    end

    def handle_call({:market_list_active}, _from, state) do
      markets = Betunfair.Repo.all(Betunfair.Market)
      case markets do
        [] ->
          {:reply, {:error, "No hay mercados"}, state}
        _markets ->
          active_markets = Enum.filter(markets, fn market -> market.status == "active" end)
          market_ids = Enum.map(active_markets, &(&1.id))
          {:reply, {:ok, market_ids}, state}
      end
    end


    def market_create(name, description) do
      case GenServer.call(:market_gestor, {:market_create, name, description}) do
        {:ok, market_id} ->
          {:ok, market_id}
        {:error, reason, texto} ->
          {:error, reason, texto}
      end
    end

    def market_list() do
      case GenServer.call(:market_gestor, {:market_list}) do
        {:ok, ids} ->
          {:ok, ids}
        {:error, reason} ->
          {:error, reason}
      end
    end

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

    def child_spec({:args, child_name, market_id}) do
      %{
        id: child_name,
        start: {__MODULE__, :start_link, [market_id]},
        type: :worker,
        restart: :permanent,
        shutdown: 500
      }
    end

    def start_link(market_id) do
      child_name = :"market_#{market_id}" #nombre del hijo
      GenServer.start_link(__MODULE__, market_id, name: child_name)
    end

    def init(market_id) do
      IO.puts("Market created with ID: #{market_id}")
      {:ok, market_id}
    end



  end

  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :description, :status])
  end
end
