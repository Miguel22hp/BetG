defmodule Betunfair.Bet_Tests do
  use Betunfair.DataCase, async: false

  setup do
    Betunfair.Bet.SupervisorBet.start_link(:a)
    Betunfair.Market.SupervisorMarket.start_link(:a)
    Betunfair.Matched.SupervisorMatched.start_link(:a)
    Betunfair.User.SupervisorUser.start_link(:a)

    #isolate database transactions for testing
    Ecto.Adapters.SQL.Sandbox.checkout(Betunfair.Repo)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :market_gestor)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :user_gestor)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :bet_gestor)
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :matched_gestor)

    :ok
  end

  #most of tests are based around backing bets. this same behaviour is applied to laying bets

  test "create a backing bet for an event/market" do
    #-----dummy user & market (+ matched and gestor_bet_market processes)
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    #-----

    Betunfair.User.OperationsUser.user_deposit(user_id, 100)
    assert {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, 10, 1.5)
  end

  test "create a laying bet for an event/market" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    Betunfair.User.OperationsUser.user_deposit(user_id, 100)
    assert {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_lay(user_id, market_id, 10, 1.5)
  end

  test "create a backing bet for an event/market with insufficient funds" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 999

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

  test "create a backing bet for an event/market with negative funds" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = -100
    bet_deposit = 10

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

  test "cancel a backing bet" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)

    process_name = :"bet_#{bet_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    assert :ok = Betunfair.Bet.OperationsBet.bet_cancel(bet_id)
  end

  test "cancel a non existing bet" do
    assert {:error, _} = Betunfair.Bet.OperationsBet.bet_cancel(999)
  end

  test "get a bet by id" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)

    process_name = :"bet_#{bet_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    {:ok, bet} = Betunfair.Bet.OperationsBet.bet_get(bet_id)
    assert bet.user_id == user_id
    assert bet.market_id == market_id
    assert bet.original_stake == bet_deposit
    assert bet.remaining_stake == bet_deposit
    assert bet.odds == 1.5
    assert bet.status == :active
    assert bet.matched_bets == []
  end

  test "get a non existing bet" do
    assert {:error, _} = Betunfair.Bet.OperationsBet.bet_get(999)
  end

  #market cancel
  test "create a bet on a market that is not active" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    Betunfair.Market.OperationsMarket.market_cancel(market_id)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

  test "get a bet by id which market is cancelled" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    {:ok, bet_id} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
    Betunfair.Market.OperationsMarket.market_cancel(market_id)

    process_name = :"bet_#{bet_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    {:ok, bet} = Betunfair.Bet.OperationsBet.bet_get(bet_id)
    assert bet.status == :market_cancelled
  end

  #market settle

  test "back bet an event that is settled to true" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10
    market_settled = false

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    Betunfair.Market.OperationsMarket.market_settle(market_id, market_settled)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

  test "back bet an event that is settled to false" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10
    market_settled = false

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    Betunfair.Market.OperationsMarket.market_settle(market_id, market_settled)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

  #market freeze

  test "back bet an event that is frozen" do
    {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
    process_name = :"user_#{user_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    {:ok, market_id} = Betunfair.Market.GestorMarket.market_create("Market 1", "active")
    process_name = :"market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"match_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
    process_name = :"gestor_bet_market_#{market_id}"
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

    user_deposit = 100
    bet_deposit = 10
    market_settled = false

    Betunfair.User.OperationsUser.user_deposit(user_id, user_deposit)
    Betunfair.Market.OperationsMarket.market_settle(market_id, market_settled)
    Betunfair.Market.OperationsMarket.market_freeze(market_id)
    assert {:error, _message} = Betunfair.Bet.GestorMarketBet.bet_back(user_id, market_id, bet_deposit, 1.5)
  end

end
