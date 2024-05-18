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
        Logger.info("Usuario obtenido exitosamente: #{inspect(user)}")
        IO.puts("User: #{inspect(user)}")
        render(conn, "profile.html", user: %{
          id: id,
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
end
