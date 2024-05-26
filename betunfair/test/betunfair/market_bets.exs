defmodule Betunfair.MarketTest do
  use Betunfair.DataCase, async: false

  setup do
    Betunfair.Bet.SupervisorBet.start_link(:a)
    Betunfair.Market.SupervisorMarket.start_link(:a)
    Betunfair.Matched.SupervisorMatched.start_link(:a)
    Betunfair.User.SupervisorUser.start_link(:a)

    Ecto.Adapters.SQL.Sandbox.checkout(Betunfair.Repo)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :market_gestor) # Permitir la conexión de sandbox para el proceso del GenServer market_gestor
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :user_gestor)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :bet_gestor)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :matched_gestor)

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
      {:ok, _id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
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


  describe "Market Cancel Test: " do
    test "cancel a market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :active}}
      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :cancelled}}
    end

    test "cancel a non existing market" do
      assert Betunfair.Market.OperationsMarket.market_cancel(1) == {:error, "Market was not found"}
    end

    test "cancel a market that is already canceled" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == {:error, "Market is not active"}
    end

    test "cancel a market and checked if the users recieve their money back with not matched bets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")

      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      {:ok, _bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 100.0, 5)
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 0}}
      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 100.0}}
    end

    test "cancel a market and checked if the users recieve their money back with matched bets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 8,odds: 1.5, matched_bets: [bet_id2],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 0,odds: 1.5, matched_bets: [bet_id],status: :active, bet_type: "lay"}}

      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 50}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 79}}
      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 100.0}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 100.0}}

    end


  end

  describe "Market Frozen Test: " do
    test "freeze a market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :active}}
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :frozen}}
    end

    test "freeze a non existing market" do
      assert Betunfair.Market.OperationsMarket.market_freeze(1) == {:error, "Market was not found"}
    end

    test "freeze a market that is already frozen" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == {:error, "Market is not active"}
    end

    test "freeze a market that is cancelled" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == {:error, "Market is not active"}
    end

    test "freeze a market that is settle" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == {:error, "Market is not active"}
    end

    test "freeze a market and checked if the users recieve their money back with not matched bets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")

      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      {:ok, _bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 100.0, 5)
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 0}}
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 100.0}}
    end

    test "cancel a market and checked if the users recieve their money back with matched bets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 8,odds: 1.5, matched_bets: [bet_id2],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 0,odds: 1.5, matched_bets: [bet_id],status: :active, bet_type: "lay"}}

      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 50}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 79}}
      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 58}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 79}}

    end

  end

  describe "Market Pending Bets Test: " do

    test "Market obtain bets of a market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}
      assert Betunfair.Market.OperationsMarket.market_pending_backs(market_id) == {:ok, [{1.5, bet_id}]}
      assert Betunfair.Market.OperationsMarket.market_pending_lays(market_id) == {:ok, [{1.5, bet_id2}]}
      assert Betunfair.Market.OperationsMarket.market_bets(market_id) == {:ok, [bet_id, bet_id2]}
    end

    test "Market obtain bets of a non existing market" do
      assert Betunfair.Market.OperationsMarket.market_pending_backs(1) == {:error, "Market was not found"}
      assert Betunfair.Market.OperationsMarket.market_pending_lays(1) == {:error, "Market was not found"}
      assert Betunfair.Market.OperationsMarket.market_bets(1) == {:error, "Market was not found"}
    end

    test "Market obtain bets of a market with no bet" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_pending_backs(market_id) == {:ok, []}
      assert Betunfair.Market.OperationsMarket.market_pending_lays(market_id) == {:ok, []}
      assert Betunfair.Market.OperationsMarket.market_bets(market_id) == {:ok, []}
    end

    test "Market obtain bets of a market matched" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_pending_backs(market_id) == {:ok, [{1.5, bet_id}]}
      assert Betunfair.Market.OperationsMarket.market_pending_lays(market_id) == {:ok, []}
      assert Betunfair.Market.OperationsMarket.market_bets(market_id) == {:ok, [bet_id, bet_id2]}
    end


  end

  describe "Market Match Test: " do

    test "Match a Market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 8,odds: 1.5, matched_bets: [bet_id2],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 0,odds: 1.5, matched_bets: [bet_id],status: :active, bet_type: "lay"}}

    end

    test "Match a Market with no Bets" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok
    end

    test "Match a non existing Market" do
      assert Betunfair.Market.OperationsMarket.market_match(1) == {:error, "Market was not found"}
    end
  end

  describe "Market Get Test: " do
    test "Get a Market" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :active}}
    end

    test "Get a non existing Market" do
      assert Betunfair.Market.OperationsMarket.market_get(1) == {:error, "Market was not found"}
    end

    test "Get a Market that is cancelled" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :cancelled}}
    end

    test "Get a Market that is frozen" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: :frozen}}
    end

    test "Get a Market that is settled to true" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, true}}}
    end

    test "Get a Market that is settled to false" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, false) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, false}}}
    end
  end

  describe "Market Settle Test: " do
    test "Settle a Market to true" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, true}}}
    end

    test "Settle a Market to false" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, false) == :ok
      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, false}}}
    end

    test "Settle a non existing Market" do
      assert Betunfair.Market.OperationsMarket.market_settle(1, true) == {:error, "Market was not found"}
    end

    test "Settle a Market that is already settled" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok
      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == {:error, "Market is not active"}
    end

    test "Settle a Market that is cancelled" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_cancel(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == {:error, "Market is not active"}
    end

    test "Settle a Market that is frozen" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"market_#{market_id}" # Construye el átomo
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.Market.OperationsMarket.market_freeze(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok
    end

    test "Settle a Market Matched to true" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_settle(market_id, true) == :ok

      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, true}}}

      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 79}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 79}}

    end

    test "Settle a Market Matched to false" do
      {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "A test market")
      process_name = :"match_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      process_name = :"market_#{market_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name2 = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      {:ok, user_id_2} = Betunfair.User.GestorUser.user_create("2", "User 2")
      process_name2 = :"user_#{user_id_2}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      process_name = :"gestor_bet_market_#{market_id}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_deposit(user_id_2, 100.0) == :ok
      {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id,market_id, 50, 1.5)
      {:ok, bet_id2} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id_2,market_id, 21, 1.5)
      process_name = :"bet_#{bet_id}"
      process_name2 = :"bet_#{bet_id2}"
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name2)

      assert Betunfair.Bet.OperationsBet.bet_get(bet_id) == {:ok, %{user_id: user_id, market_id: market_id, original_stake: 50, remaining_stake: 50,odds: 1.5, matched_bets: [],status: :active, bet_type: "back"}}
      assert Betunfair.Bet.OperationsBet.bet_get(bet_id2) == {:ok, %{user_id: user_id_2, market_id: market_id, original_stake: 21, remaining_stake: 21,odds: 1.5, matched_bets: [],status: :active, bet_type: "lay"}}

      assert Betunfair.Market.OperationsMarket.market_match(market_id) == :ok
      assert Betunfair.Market.OperationsMarket.market_settle(market_id, false) == :ok

      assert Betunfair.Market.OperationsMarket.market_get(market_id) == {:ok, %{name: "Market 1", description: "A test market",status: {:settled, false}}}

      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 58}}
      assert Betunfair.User.OperationsUser.user_get(user_id_2) == {:ok, %{name: "User 2",id: "2",balance: 79+42}}

    end
  end

end
