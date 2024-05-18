defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller
  alias Betunfair.User.OperationsUser
  require Logger

  def profile(conn, %{"id" => id}) do
    token = Plug.CSRFProtection.get_csrf_token()
    redirect_to_profile(conn, id, token)
  end

  def add_funds(conn, %{"id" => id, "amount" => amount}) do
    case OperationsUser.user_deposit(id, String.to_integer(amount)) do
      {:ok} ->
        Logger.info("Fondos añadidos exitosamente para el usuario #{id}")
        conn
        |> put_flash(:info, "Funds added successfully.")
        |> redirect(to: "/users/#{id}/profile")
      {:error, reason} ->
        Logger.error("Error al añadir fondos para el usuario #{id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  def withdraw_funds(conn, %{"id" => id, "amount" => amount}) do
    case OperationsUser.user_withdraw(id, String.to_integer(amount)) do
      {:ok} ->
        Logger.info("Fondos retirados exitosamente para el usuario #{id}")
        conn
        |> put_flash(:info, "Funds withdrawn successfully.")
        |> redirect(to: "/users/#{id}/profile")
      {:error, reason} ->
        Logger.error("Error al retirar fondos para el usuario #{id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp redirect_to_profile(conn, id, token) do
    case OperationsUser.user_get(id) do
      {:ok, user} ->
        case mock_get_user_bets(id) do
          {:ok, bets} ->
            Logger.info("Usuario obtenido exitosamente: #{inspect(user)}")
            render(conn, "profile.html", user: %{
              id: id,
              name: user.name,
              balance: user.balance,
              csrf_token: token,
              bets: bets
            })
          {:error, reason} ->
            Logger.error("Error al obtener las apuestas del usuario: #{reason}")
            conn
            |> put_flash(:error, reason)
            |> redirect(to: "/")
        end
      {:error, reason} ->
        Logger.error("Error al obtener el usuario: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp mock_get_user_bets(_id) do
    {:ok, [
      %{id: 1, amount: 50, status: "win", type: "back"},
      %{id: 2, amount: 30, status: "lose", type: "lay"},
      %{id: 3, amount: 20, status: "pending", type: "back"},
      %{id: 4, amount: 40, status: "win", type: "lay"},
      %{id: 5, amount: 25, status: "lose", type: "back"},
      %{id: 6, amount: 60, status: "pending", type: "lay"},
      %{id: 7, amount: 35, status: "win", type: "back"},
      %{id: 8, amount: 45, status: "lose", type: "lay"},
      %{id: 9, amount: 55, status: "pending", type: "back"},
      %{id: 10, amount: 70, status: "win", type: "lay"}
    ]}
  end
end
