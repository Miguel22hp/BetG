defmodule BetunfairWeb.BetsController do
  use BetunfairWeb, :controller
  alias Betunfair.Market.OperationsMarket
  alias Betunfair.Bet.OperationsBet
  alias Betunfair.Bet.GestorMarketBet
  require Logger

  def bets(conn, %{"id" => market_id}) do
    case OperationsMarket.market_get(market_id) do
      {:ok, market} ->
        case OperationsMarket.market_bets(market_id) do
          {:ok, bet_ids} ->
            bets = Enum.map(bet_ids, fn bet_id ->
              case OperationsBet.bet_get(bet_id) do
                {:ok, bet} -> bet
                _ -> nil
              end
            end)
            |> Enum.reject(&is_nil/1)

            render(conn, :bets,
              market_id: market_id,
              market: market,
              bets: bets,
              csrf_token: Plug.CSRFProtection.get_csrf_token()
            )

          {:error, reason} ->
            Logger.error("Failed to load bets: #{reason}")
            conn
            |> put_flash(:error, "Failed to load bets: #{reason}")
            |> redirect(to: "/markets")
        end

      {:error, reason} ->
        Logger.error("Failed to load market: #{reason}")
        conn
        |> put_flash(:error, "Failed to load market: #{reason}")
        |> redirect(to: "/markets")
    end
  end

  def create_bet(conn, %{"market_id" => market_id, "type" => type, "amount" => amount, "odds" => odds, "user_id" => user_id}) do
    amount = String.to_float(amount)
    odds = String.to_float(odds)

    result =
      case type do
        "lay" -> GestorMarketBet.bet_lay(user_id, market_id, amount, odds)
        "back" -> GestorMarketBet.bet_back(user_id, market_id, amount, odds)
      end

    case result do
      {:ok, _bet_id} ->
        conn
        |> put_flash(:info, "Bet successfully created.")
        |> redirect(to: "/markets")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create bet: #{reason}")
        |> redirect(to: "/markets")
    end
  end
end
