defmodule BetunfairWeb.ProfileController do
  @moduledoc """
  The `BetunfairWeb.ProfileController` module handles actions related to the user's profile in the Betunfair web application. This module uses `BetunfairWeb`, an alias of the web application context, and provides the following functionalities:

  - `profile/2`: Displays the user's profile.
  - `add_funds/2`: Adds funds to the user's account.
  - `withdraw_funds/2`: Withdraws funds from the user's account.
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

  @doc false
  @spec redirect_to_profile(Plug.Conn.t(), String.t(), String.t()) :: Plug.Conn.t()
  defp redirect_to_profile(conn, id, token) do
    case OperationsUser.user_get(id) do
      {:ok, user} ->
        case OperationsUser.user_bets(id) do
          bet_ids ->
            # Fetch the details of each bet along with the market information
            bets = Enum.map(bet_ids, fn bet_id ->
              case OperationsBet.bet_get(bet_id) do
                {:ok, bet} ->
                  case OperationsMarket.market_get(bet.market_id) do
                    {:ok, market} -> Map.put(bet, :market, market)
                    {:error, _reason} -> bet
                  end
                {:error, _reason} -> nil
              end
            end)
            |> Enum.filter(&(&1 != nil)) # Remove invalid bets

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
end
