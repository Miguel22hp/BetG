defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller
  alias Betunfair.User.OperationsUser
  require Logger

  def profile(conn, %{"id" => user_id}) do
    token = Plug.CSRFProtection.get_csrf_token()
    redirect_to_profile(conn, user_id, token)
  end

  def add_funds(conn, %{"id" => user_id, "amount" => amount}) do
    case OperationsUser.user_deposit(user_id, String.to_integer(amount)) do
      :ok ->
        Logger.info("Fondos añadidos exitosamente para el usuario #{user_id}")
        conn
        |> put_flash(:info, "Funds added successfully.")
        |> redirect(to: "/profile/#{user_id}")
      {:error, reason} ->
        Logger.error("Error al añadir fondos para el usuario #{user_id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  def withdraw_funds(conn, %{"id" => user_id, "amount" => amount}) do
    case OperationsUser.user_withdraw(user_id, String.to_integer(amount)) do
      :ok ->
        Logger.info("Fondos retirados exitosamente para el usuario #{user_id}")
        conn
        |> put_flash(:info, "Funds withdrawn successfully.")
        |> redirect(to: "/profile/#{user_id}")
      {:error, reason} ->
        Logger.error("Error al retirar fondos para el usuario #{user_id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp redirect_to_profile(conn, user_id, token) do
    case OperationsUser.user_get(user_id) do
      {:ok, user} ->
        Logger.info("Usuario obtenido exitosamente: #{inspect(user)}")
        render(conn, "profile.html", user: %{
          id: user.id,
          name: user.name,
          balance: user.balance,
          csrf_token: token
        })
      {:error, reason} ->
        Logger.error("Error al obtener el usuario: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp get_user_bets(user_id) do
    [
      %{id: 1, description: "Real Madrid vs Atlético - La Liga", amount: 200, odd: 3.5, status: "Layed"}
    ]
  end
end
