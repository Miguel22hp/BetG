defmodule BetunfairWeb.MarketsController do
  use BetunfairWeb, :controller
  alias Betunfair.Market.GestorMarket
  alias Betunfair.Market.OperationsMarket
  require Logger

  @doc """
  Handles the action to list markets.

  Calls `GestorMarket.market_list/0` to get a list of market IDs.
  For each market ID, it calls `OperationsMarket.market_get/1` to fetch market data.
  The markets are filtered into three categories: active, frozen, and cancelled.
  Renders the "markets.html" template with the categorized market lists and a CSRF token.

  If an error occurs while fetching the market list, logs the error and redirects to the homepage with an error flash message.
  """
  @spec list_markets(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def list_markets(conn, _params) do
    case GestorMarket.market_list() do
      {:ok, market_ids} ->
        markets = Enum.map(market_ids, fn id ->
          case OperationsMarket.market_get(id) do
            {:ok, market} ->
              Logger.debug("Fetched market: #{inspect(market)}")
              Map.put(market, :id, id) # Adds the id to the market map
            _ -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)


        active_markets = Enum.filter(markets, &(&1.status == :active))
        frozen_markets = Enum.filter(markets, &(&1.status == :frozen))
        cancelled_markets = Enum.filter(markets, &(&1.status == :cancelled))
        settled_markets_true = Enum.filter(markets, &(&1.status == {:settled, true}))
        settled_markets_false = Enum.filter(markets, &(&1.status == {:settled, false}))

        render(conn, "markets.html",
          active_markets: active_markets,
          frozen_markets: frozen_markets,
          cancelled_markets: cancelled_markets,
          settled_markets_false: settled_markets_false,
          settled_markets_true: settled_markets_true,
          csrf_token: Plug.CSRFProtection.get_csrf_token()
        )

      {:error, reason} ->
        Logger.error("Failed to load markets: #{reason}")
        conn
        |> put_flash(:error, "Failed to load markets: #{reason}")
        |> redirect(to: "/")
    end
  end
end
