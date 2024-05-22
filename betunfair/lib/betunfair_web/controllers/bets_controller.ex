defmodule BetunfairWeb.BetsController do
  use BetunfairWeb, :controller
  require Logger
  alias Betunfair.Market.GestorMarket
  alias Betunfair.Market.OperationsMarket
  alias Betunfair.Bet.OperationsBet

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

        Logger.info("Markets loaded: #{inspect(markets)}")
        render(conn, "bets.html", markets: markets, selected_market: nil, back_bets: [], lay_bets: [])
      {:error, reason} ->
        Logger.error("Failed to load markets: #{reason}")
        render(conn, "bets.html", markets: [], error: reason)
    end
  end

  def load_bets(conn, %{"market_id" => market_id}) do
    market_id = String.to_integer(market_id)
    Logger.info("Loading bets for market_id: #{market_id}")

    case OperationsMarket.market_pending_backs(market_id) do
      {:ok, back_bet_tuples} ->
        back_bets = for {odds, bet_id} <- back_bet_tuples do
          case OperationsBet.bet_get(bet_id) do
            {:ok, bet} -> Map.put(bet, :id, bet_id)
            {:error, _reason} -> nil
          end
        end
        |> Enum.filter(& &1) # Filtramos las apuestas nulas

        Logger.info("Back bets: #{inspect(back_bets)}")

        case OperationsMarket.market_pending_lays(market_id) do
          {:ok, lay_bet_tuples} ->
            lay_bets = for {odds, bet_id} <- lay_bet_tuples do
              case OperationsBet.bet_get(bet_id) do
                {:ok, bet} -> Map.put(bet, :id, bet_id)
                {:error, _reason} -> nil
              end
            end
            |> Enum.filter(& &1) # Filtramos las apuestas nulas

            Logger.info("Lay bets: #{inspect(lay_bets)}")

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
                Logger.error("Failed to reload markets: #{reason}")
                render(conn, "bets.html", markets: [], error: reason)
            end

          {:error, _reason} ->
            Logger.error("Unable to load lay bets for market_id: #{market_id}")
            render(conn, "bets.html", error: "Unable to load lay bets.")
        end

      {:error, _reason} ->
        Logger.error("Unable to load back bets for market_id: #{market_id}")
        render(conn, "bets.html", error: "Unable to load back bets.")
    end
  end
end
