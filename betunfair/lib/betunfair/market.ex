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
      {Betunfair.Market.GestorMarket, []}
    ]
      Supervisor.init(children, strategy: :one_for_one)

    end
  end

  defmodule GestorMarket do
    use GenServer

    def start_link(args) do
      GenServer.start_link(__MODULE__, [], name: :gestor_market)
    end

    def init() do
      {:ok}
    end

    @doc """
      El servidor recibe la llamada para crear un mercado. Si no existe un mercado
      con el mismo nombre, se procede a crearlo.
    """
    def handle_call({:market_create, name, description}, _from, state) do
      case Betunfair.Repo.get_by(Betunfair.Market, name: name) do
        nil ->
          # No hay ningún mercado con el mismo nombre, puedes proceder a crear el mercado
          # Aquí iría la lógica para crear el mercado
          case add_child_operation(name, description) do
            {:ok, market_id} ->
              {:reply, {:ok, market_id}, state}
            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        _market ->
          # Ya existe un mercado con el mismo nombre, maneja este caso según tus necesidades
          # Por ejemplo, podrías devolver un error o lanzar una excepción
          {:reply, {:error, "Ya existe un mercado con el mismo nombre"}, state}
      end
    end

    @doc """
      Si el mercado se introduce correctamente en la base de datos, se procede a crear
      un proceso hijo, con nombre market_(num), que se encargará de las operaciones.
      num es el id asociado al mercado creado en la base de datos.
    """
    def add_child_operation(name, description) do
      case insert_market(name, description) do
        {:ok, market} ->
          child_name = :"market_supervisor#{market.id}" #nombre del hijo
          case Supervisor.start_child(:market_supervisor, {Betunfair.Market.SupervisorOperationsMarket, {:args, child_name, market.id}}) do
            {:ok, pid} ->
              {:ok, market.id}
            {:error, reason} ->
              {:error, reason}
          end
        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
      Inserta un mercado en la base de datos. Devuelve ok y la referencia si lo consigue, o
      error y el motivo si no lo consigue.s
    """
    def insert_market(name, description) do
      changeset = Betunfair.Market.changeset(%Betunfair.Market{}, %{name: name, description: description, status: "active"})

      case Betunfair.Repo.insert(changeset) do
        {:ok, market} ->
          {:ok, market}
        {:error, changeset} ->
          {:error, "No se pudo insertar el mercado: #{inspect(changeset.errors)}"}
      end
    end


    @doc """
      El servidor recibe la llamada para listar los mercados. Devuelve una lista con los mercados
      que se encuentran en la base de datos.
    """
    def handle_call({:market_list}, _from, state) do
      markets = Betunfair.Repo.all(Betunfair.Market)
      market_ids = Enum.map(markets, & &1.id)
      {:reply, {:ok,market_ids}, state}
    end

    @doc """
      El servidor recibe la llamada para listar los mercados activos. Devuelve una lista con los mercados
      activos que se encuentran en la base de datos.
    """
    def handle_call({:market_list_active}, _from, state) do
      markets =Betunfair.Repo.all(
                from m in Betunfair.Market,
                where: m.status == "active"
              )
      market_ids = Enum.map(markets, & &1.id)
      {:reply, {:ok,market_ids}, state}
    end

    #--- Client ---
    @doc """
      Llama al servidor para que cree un mercado
    """
    def market_create(name, description) do
      case GenServer.call(:gestor_market, {:market_create, name, description}) do
        {:ok, market_id} ->
          {:ok, market_id}
        {:error, reason} ->
          {:error, reason}
      end
    end

    @doc """
      Llama al servidor para que liste los mercados
    """
    def market_list() do
      GenServer.call(:gestor_market, {:market_list})
    end

    @doc """
      Llama al servidor para que liste los mercados activos
    """
    def market_list_active() do
      GenServer.call(:gestor_market, {:market_list_active})
    end

  end

  defmodule SupervisorOperationsMarket do
    use Supervisor

    def start_link({:args, child_name, id}) do
      Supervisor.start_link(__MODULE__, {:args, child_name, id}, name: child_name)
    end

    def init({:args, child_name, id}) do
      # consturir el nombre del hijo, que será market_id
      children_name = :"market_#{id}"
      children = [
        {Betunfair.Market.OperationsMarket, {:args, children_name, id}}
      ]
      Supervisor.init(children, strategy: :one_for_one)
    end
  end

  defmodule OperationsMarket do
    use GenServer

    def start_link({:args, children_name, id}) do
      GenServer.start_link(__MODULE__, {:args, children_name, id}, name: children_name)
    end

    def init({:args, children_name, id}) do
      {:ok, id}
    end


  end



  @doc false
  def changeset(market, attrs) do
    market
    |> cast(attrs, [:name, :description, :status])
    |> validate_required([:name, :description, :status])
  end
end
