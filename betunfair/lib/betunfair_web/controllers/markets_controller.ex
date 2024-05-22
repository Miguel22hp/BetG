defmodule BetunfairWeb.MarketsController do
  use BetunfairWeb, :controller
  alias Betunfair.Market.GestorMarket
  alias Betunfair.Market.OperationsMarket

  def list_markets(conn, _params) do
    case GestorMarket.market_list() do
      {:ok, market_ids} ->
        markets = Enum.map(market_ids, fn id ->
          case OperationsMarket.market_get(id) do
            {:ok, market} -> market
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

        active_markets = Enum.filter(markets, &(&1.status == "active"))
        frozen_markets = Enum.filter(markets, &(&1.status == "freeze"))
        cancelled_markets = Enum.filter(markets, &(&1.status == "cancelled"))

        render(conn, "markets.html",
          active_markets: active_markets,
          frozen_markets: frozen_markets,
          cancelled_markets: cancelled_markets,
          csrf_token: Plug.CSRFProtection.get_csrf_token()
        )

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to load markets: #{reason}")
        |> redirect(to: "/")
    end
  end
end
