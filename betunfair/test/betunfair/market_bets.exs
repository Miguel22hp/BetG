defmodule Betunfair.MarketTest do
  use Betunfair.DataCase, async: true

  setup do
    Betunfair.Bet.SupervisorBet.start_link(:a)
    Betunfair.Market.SupervisorMarket.start_link(:a)
    Betunfair.Matched.SupervisorMatched.start_link(:a)
    Betunfair.User.SupervisorUser.start_link

    Ecto.Adapters.SQL.Sandbox.checkout(Betunfair.Repo)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :market_gestor) # Permitir la conexión de sandbox para el proceso del GenServer market_gestor
    :ok
  end


  describe "Market Creation Test: " do
    test "create a market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      assert {:ok, market_id+1} == Betunfair.Market.GestorMarket.market_create("Market 2", "A test market")
      assert {:ok, market_id+2} == Betunfair.Market.GestorMarket.market_create("Market 3", "A test market")
    end

    test "market get data " do
      {:ok, id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      market = Betunfair.Market.OperationsMarket.market_get(id)
      assert market == {:ok, %{name: "Market 1", description: "A test market",status: :active}}
    end

    test "create a market with the same id" do
      {:ok, id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      assert Betunfair.Market.GestorMarket.market_create("Market 1", "A test market") == {:error, "A market with the same name already exists"}
    end
  end

  describe "Market List Test: " do
    test "list markets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      {:ok, market_id_2} = Betunfair.Market.GestorMarket.market_create("Market 2", "A test market")
      {:ok, market_id_3} = Betunfair.Market.GestorMarket.market_create("Market 3", "A test market")
      assert Betunfair.Market.GestorMarket.market_list() == {:ok, [market_id, market_id_2, market_id_3]}
      assert Betunfair.Market.GestorMarket.market_list_active() == {:ok, [market_id, market_id_2, market_id_3]}
    end

    test "list markets with no markets" do
      assert Betunfair.Market.GestorMarket.market_list() == {:ok, []}
      assert Betunfair.Market.GestorMarket.market_list_active() == {:ok, []}
    end

    test "list markets with no active markets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      Betunfair.Market.OperationsMarket.market_cancel(market_id)
      assert Betunfair.Market.GestorMarket.market_list() == {:ok, [market_id]}
      assert Betunfair.Market.GestorMarket.market_list_active() == {:ok, []}
    end
  end

end
