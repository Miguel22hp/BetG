defmodule BetunfairWeb.ProfileController do
  @moduledoc """
  The `BetunfairWeb.ProfileController` module handles actions related to the user's profile in the Betunfair web application. This module uses `BetunfairWeb`, an alias of the web application context, and provides the following funcionalidades:

  - `profile/2`: Displays the user's profile.
  - `add_funds/2`: Adds funds to the user's account.
  - `withdraw_funds/2`: Withdraws funds from the user's account.
  - `cancel_bet/2`: Cancels a bet.
  """
  use BetunfairWeb, :controller
  alias Betunfair.User.OperationsUser
  alias Betunfair.Bet.OperationsBet
  alias Betunfair.Market.OperationsMarket
  require Logger

  @doc """
  Retrieves the user's profile by their ID and renders it in the "profile.html" view. Uses a CSRF token for request security.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"id" => id}`: URL parameter containing the user's ID.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec profile(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def profile(conn, %{"id" => id}) do
    token = Plug.CSRFProtection.get_csrf_token()
    redirect_to_profile(conn, id, token)
  end

  @doc """
  Adds funds to the user's account.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"id" => id, "amount" => amount}`: URL parameters containing the user's ID and the amount to add.

  ## Actions:
    - Calls `OperationsUser.user_deposit/2` to add the funds.
    - If the operation is successful, redirects to the user's profile with a success message.
    - If there is an error, redirects to the home page with an error message.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec add_funds(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add_funds(conn, %{"id" => id, "amount" => amount}) do
    case OperationsUser.user_deposit(id, String.to_float(amount)) do
      :ok ->
        Logger.info("Funds added successfully for user #{id}")
        conn
        |> put_flash(:info, "Funds added successfully.")
        |> redirect(to: "/users/#{id}/profile")
      {:error, reason} ->
        Logger.error("Error adding funds for user #{id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  @doc """
  Withdraws funds from the user's account.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"id" => id, "amount" => amount}`: URL parameters containing the user's ID and the amount to withdraw.

  ## Actions:
    - Calls `OperationsUser.user_withdraw/2` to withdraw the funds.
    - If the operation is successful, redirects to the user's profile with a success message.
    - If there is an error, redirects to the home page with an error message.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec withdraw_funds(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def withdraw_funds(conn, %{"id" => id, "amount" => amount}) do
    case OperationsUser.user_withdraw(id, String.to_float(amount)) do
      :ok ->
        Logger.info("Funds withdrawn successfully for user #{id}")
        conn
        |> put_flash(:info, "Funds withdrawn successfully.")
        |> redirect(to: "/users/#{id}/profile")
      {:error, reason} ->
        Logger.error("Error withdrawing funds for user #{id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  @doc """
  Cancels a bet by its ID.

  ## Parameters:
    - `conn`: HTTP connection.
    - `%{"bet_id" => bet_id, "user_id" => user_id}`: URL parameter containing the bet's ID and user's ID.

  ## Actions:
    - Calls `OperationsBet.cancel_bet/1` to cancel the bet.
    - If the operation is successful, redirects to the user's profile with a success message.
    - If there is an error, redirects to the user's profile with an error message.

  ## Returns:
    - `Plug.Conn.t()`: The updated connection.
  """
  @spec cancel_bet(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def cancel_bet(conn, %{"bet_id" => bet_id, "user_id" => user_id}) do
    case OperationsBet.bet_cancel(bet_id) do
      :ok ->
        Logger.info("Bet cancelled successfully: #{bet_id}")
        conn
        |> put_flash(:info, "Bet cancelled successfully.")
        |> redirect(to: "/users/#{user_id}/profile")
      {:error, reason} ->
        Logger.error("Error cancelling bet: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/users/#{user_id}/profile")
    end
  end

  defp redirect_to_profile(conn, id, token) do
    case OperationsUser.user_get(id) do
      {:ok, user} ->
        case OperationsUser.user_bets(id) do
          bet_ids ->
            bets = Enum.map(bet_ids, fn bet_id ->
              case OperationsBet.bet_get(bet_id) do
                {:ok, bet} ->
                  case OperationsMarket.market_get(bet.market_id) do
                    {:ok, market} ->
                      Map.put(bet, :market, market)
                      |> Map.put(:bet_id, bet_id)
                      |> format_bet()
                    {:error, _reason} -> format_bet(bet |> Map.put(:bet_id, bet_id))
                  end
                {:error, _reason} -> nil
              end
            end)
            |> Enum.filter(&(&1 != nil))

            Logger.info("User retrieved successfully: #{inspect(user)}")
            render(conn, "profile.html", user: %{
              id: id,
              name: user.name,
              balance: user.balance,
              csrf_token: token,
              bets: bets
            })
          {:error, reason} ->
            Logger.error("Error fetching user's bets: #{reason}")
            conn
            |> put_flash(:error, reason)
            |> redirect(to: "/")
        end
      {:error, reason} ->
        Logger.error("Error fetching user: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp format_bet(bet) do
    # Convert any complex structures into simpler representations
    Map.update!(bet, :status, &Atom.to_string/1)
  end
end
