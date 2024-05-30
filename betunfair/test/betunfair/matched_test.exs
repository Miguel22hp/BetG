defmodule OperationsMatchedTest do
  use ExUnit.Case
  alias Betunfair.{Repo, Bet, User, Market, Matched, Matched.OperationsMatched}
  import Ecto.Query


  setup do

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Betunfair.Repo)
    # Create users
    user_a = %User{id_users: "a", name: "User A", balance: 1000.0} |> Repo.insert!()
    user_b = %User{id_users: "b", name: "User B", balance: 1000.0} |> Repo.insert!()
    user_c = %User{id_users: "c", name: "User C", balance: 1000.0} |> Repo.insert!()
    user_d = %User{id_users: "d", name: "User D", balance: 1000.0} |> Repo.insert!()
    user_e = %User{id_users: "e", name: "User E", balance: 1000.0} |> Repo.insert!()
    user_f = %User{id_users: "f", name: "User F", balance: 1000.0} |> Repo.insert!()
    user_g = %User{id_users: "g", name: "User G", balance: 1000.0} |> Repo.insert!()

    # Create market
    market = %Market{name: "Test Market", description: "A test market", status: "active"} |> Repo.insert!()

    {:ok, market_id: market.id, users: [user_a, user_b, user_c, user_d, user_e, user_f, user_g]}
  end

  defp create_bet(user, odds, stake, type, market_id) do
    %Bet{
      user_id: user.id,
      odds: odds,
      original_stake: stake,
      remaining_stake: stake,
      type: type,
      market_id: market_id
    }
    |> Repo.insert!()
  end

  test "initial unmatched bets and new back bet by user f", %{market_id: market_id, users: users} do
    # Create initial unmatched bets
    create_bet(Enum.at(users, 0), 3.0, 20.0, "back", market_id) # user a
    create_bet(Enum.at(users, 1), 2.0, 14.0, "back", market_id) # user b
    create_bet(Enum.at(users, 2), 1.53, 5.0, "back", market_id) # user c
    create_bet(Enum.at(users, 3), 1.5, 21.0, "lay", market_id) # user d
    create_bet(Enum.at(users, 4), 1.1, 400.0, "lay", market_id) # user e

    # Call the matching function
    OperationsMatched.match_bets(market_id)

    # Verify the new back bet by user f
    create_bet(Enum.at(users, 5), 1.5, 50.0, "back", market_id) # user f
    OperationsMatched.match_bets(market_id)

    back_bet_f = Repo.get_by(Bet, user_id: Enum.at(users, 5).id, market_id: market_id)
    lay_bet_d = Repo.get_by(Bet, user_id: Enum.at(users, 3).id, market_id: market_id)



    #IO.inspect(back_bet_f)
    #IO.inspect(lay_bet_d)

    assert back_bet_f.remaining_stake == 8.0
    assert lay_bet_d.remaining_stake == 0.0

    # matched_bets = Repo.all(from(m in Matched, where: m.market_id == ^market_id))
    # assert length(matched_bets) == 1
    # matched_bet = hd(matched_bets)
    # assert matched_bet.id_bet_backed == back_bet_f.id
    # assert matched_bet.id_bet_layed == lay_bet_d.id
    # assert matched_bet.matched_amount == Decimal.new(42)
  end

  test "new lay bet by user g", %{market_id: market_id, users: users} do
    # Create initial unmatched bets
    create_bet(Enum.at(users, 0), 3.0, 20.0, "back", market_id) # user a
    create_bet(Enum.at(users, 1), 2.0, 14.0, "back", market_id) # user b
    create_bet(Enum.at(users, 2), 1.53, 5.0, "back", market_id) # user c
    create_bet(Enum.at(users, 5), 1.5, 50.0, "back", market_id) # user f
    create_bet(Enum.at(users, 3), 1.5, 21.0, "lay", market_id) # user d
    create_bet(Enum.at(users, 4), 1.1, 400.0, "lay", market_id) # user e

    # Call the matching function
    OperationsMatched.match_bets(market_id)

    # Verify the new lay bet by user g
    create_bet(Enum.at(users, 6), 1.53, 5.0, "lay", market_id) # user g
    OperationsMatched.match_bets(market_id)

    back_bet_c = Repo.get_by(Bet, user_id: Enum.at(users, 2).id, market_id: market_id)
    back_bet_f = Repo.get_by(Bet, user_id: Enum.at(users, 5).id, market_id: market_id)
    lay_bet_g = Repo.get_by(Bet, user_id: Enum.at(users, 6).id, market_id: market_id)

    assert back_bet_c.remaining_stake == 3.11
    assert back_bet_f.remaining_stake == 0.0
    assert lay_bet_g.remaining_stake == 0.0

    # matched_bets = Repo.all(from(m in Matched, where: m.market_id == ^market_id))
    # assert length(matched_bets) == 3
  end


  test "new database values", %{market_id: market_id, users: users} do
    # Create initial unmatched bets
    create_bet(Enum.at(users, 0), 1.5, 21.0, "lay", market_id) # user a
    create_bet(Enum.at(users, 1), 1.4, 13.0, "lay", market_id) # user b
    create_bet(Enum.at(users, 2), 1.9, 40.0, "lay", market_id) # user c
    create_bet(Enum.at(users, 3), 1.3, 19.0, "back", market_id) # user d
    create_bet(Enum.at(users, 4), 1.5, 50.0, "back", market_id) # user e

    # Call the matching function
    OperationsMatched.match_bets(market_id)

    back_bet_d = Repo.get_by(Bet, user_id: Enum.at(users, 3).id, market_id: market_id)
    back_bet_e = Repo.get_by(Bet, user_id: Enum.at(users, 4).id, market_id: market_id)
    lay_bet_a = Repo.get_by(Bet, user_id: Enum.at(users, 0).id, market_id: market_id)
    lay_bet_b = Repo.get_by(Bet, user_id: Enum.at(users, 1).id, market_id: market_id)
    lay_bet_c = Repo.get_by(Bet, user_id: Enum.at(users, 2).id, market_id: market_id)


    assert back_bet_d.remaining_stake == 0.0
    assert back_bet_e.remaining_stake == 0.0
    assert lay_bet_c.remaining_stake == 9.3
    assert lay_bet_a.remaining_stake == 21.0
    assert lay_bet_b.remaining_stake == 13.0
    query = from(m in Matched)
    matched_bets = Repo.all(query)
    assert length(matched_bets) == 2
    matched1 = hd(matched_bets)
    matched2 = hd(tl(matched_bets))
    assert matched1.empty_stake == "back"
    assert matched2.empty_stake == "back"
  end
end
