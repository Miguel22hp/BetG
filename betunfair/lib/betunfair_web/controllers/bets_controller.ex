defmodule BetunfairWeb.BetsController do
  use BetunfairWeb, :controller
  alias Betunfair.Market.GestorMarket
  alias Betunfair.Market.OperationsMarket
  alias Betunfair.Bet.OperationsBet
  alias Betunfair.Bet.GestorMarketBet

  def bets(conn, _params) do
    case GestorMarket.market_list() do
      {:ok, market_ids} ->
        markets = for market_id <- market_ids do
          case OperationsMarket.market_get(market_id) do
            {:ok, market} ->
              %{id: market_id, name: market.name, description: market.description, status: market.status}
            {:error, _reason} -> nil
          end
        end
        |> Enum.filter(& &1) # Filtramos los mercados nulos

        render(conn, "bets.html", markets: markets, selected_market: nil, back_bets: [], lay_bets: [])
      {:error, reason} ->
        render(conn, "bets.html", markets: [], error: reason)
    end
  end

  def load_bets(conn, %{"market_id" => market_id}) do
    market_id = String.to_integer(market_id)

    case OperationsMarket.market_pending_backs(market_id) do
      {:ok, back_bet_tuples} ->
        back_bets = for {odds, bet_id} <- back_bet_tuples do
          case OperationsBet.bet_get(bet_id) do
            {:ok, bet} -> Map.put(bet, :id, bet_id)
            {:error, _reason} -> nil
          end
        end
        |> Enum.filter(& &1) # Filtramos las apuestas nulas

        case OperationsMarket.market_pending_lays(market_id) do
          {:ok, lay_bet_tuples} ->
            lay_bets = for {odds, bet_id} <- lay_bet_tuples do
              case OperationsBet.bet_get(bet_id) do
                {:ok, bet} -> Map.put(bet, :id, bet_id)
                {:error, _reason} -> nil
              end
            end
            |> Enum.filter(& &1) # Filtramos las apuestas nulas

            case GestorMarket.market_list() do
              {:ok, market_ids} ->
                markets = for market_id <- market_ids do
                  case OperationsMarket.market_get(market_id) do
                    {:ok, market} ->
                      %{id: market_id, name: market.name, description: market.description, status: market.status}
                    {:error, _reason} -> nil
                  end
                end
                |> Enum.filter(& &1) # Filtramos los mercados nulos

                render(conn, "bets.html", markets: markets, selected_market: market_id, back_bets: back_bets, lay_bets: lay_bets)
              {:error, reason} ->
                render(conn, "bets.html", markets: [], error: reason)
            end

          {:error, _reason} ->
            render(conn, "bets.html", error: "Unable to load lay bets.")
        end

      {:error, _reason} ->
        render(conn, "bets.html", error: "Unable to load back bets.")
    end
  end

  def back_bet(conn, %{"bet_id" => bet_id, "market_id" => market_id, "user_id" => user_id, "stake" => stake, "odds" => odds}) do
    market_id = String.to_integer(market_id)
    user_id = String.to_integer(user_id)
    bet_id = String.to_integer(bet_id)
    stake = String.to_integer(stake)
    odds = String.to_float(odds)

    case GestorMarketBet.bet_back(user_id, market_id, stake, odds) do
      {:ok, _bet_id} ->
        conn
        |> put_flash(:info, "Back bet placed successfully.")
        |> redirect(to: "/bets")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to place back bet: #{reason}")
        |> redirect(to: "/bets")
    end
  end

  def lay_bet(conn, %{"bet_id" => bet_id, "market_id" => market_id, "user_id" => user_id, "stake" => stake, "odds" => odds}) do
    market_id = String.to_integer(market_id)
    user_id = String.to_integer(user_id)
    bet_id = String.to_integer(bet_id)
    stake = String.to_integer(stake)
    odds = String.to_float(odds)

    case GestorMarketBet.bet_lay(user_id, market_id, stake, odds) do
      {:ok, _bet_id} ->
        conn
        |> put_flash(:info, "Lay bet placed successfully.")
        |> redirect(to: "/bets")
      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to place lay bet: #{reason}")
        |> redirect(to: "/bets")
    end
  end
end
