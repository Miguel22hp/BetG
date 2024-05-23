defmodule BetunfairWeb.BetsController do
  @moduledoc """
  The `BetunfairWeb.BetsController` module handles actions related to bets in the Betunfair web application. This module uses `BetunfairWeb`, an alias of the web application context, and provides the following functionalities:

  - `bets/2`: Displays the bets for a specific market.
  - `create_bet/2`: Creates a new bet for a specific market.
  """
  use BetunfairWeb, :controller
  alias Betunfair.Market.OperationsMarket
  alias Betunfair.Bet.OperationsBet
  alias Betunfair.Bet.GestorMarketBet
  require Logger

  @doc """
  Retrieves and displays the bets for a specific market.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"id" => market_id}`: URL parameter containing the market ID.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec bets(Plug.Conn.t(), map()) :: Plug.Conn.t()
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

  @doc """
  Creates a new bet for a specific market.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"market_id" => market_id, "type" => type, "amount" => amount, "odds" => odds, "user_id" => user_id}`: URL parameters containing the market ID, bet type, amount, odds, and user ID.

  ## Actions:
    - Calls `GestorMarketBet.bet_lay/4` or `GestorMarketBet.bet_back/4` to create the bet.
    - If the operation is successful, redirects to the markets page with a success message.
    - If there is an error, redirects to the markets page with an error message.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec create_bet(Plug.Conn.t(), map()) :: Plug.Conn.t()
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
