defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller
  alias Betunfair.User.OperationsUser  # Alias the OperationsUser module
  require Logger  # Import the Logger module

  def profile(conn, %{"id" => user_id}) do
    redirect_to_profile(conn, user_id)
  end

  def add_funds(conn, %{"id" => user_id, "amount" => amount}) do
    case OperationsUser.user_deposit(user_id, String.to_integer(amount)) do
      :ok ->
        Logger.info("Fondos añadidos exitosamente para el usuario #{user_id}")
        conn
        |> put_flash(:info, "Funds added successfully.")
        |> redirect_to_profile(user_id)
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
        |> redirect_to_profile(user_id)
      {:error, reason} ->
        Logger.error("Error al retirar fondos para el usuario #{user_id}: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  defp redirect_to_profile(conn, user_id) do
    case OperationsUser.user_get(user_id) do
      {:ok, user} ->
        Logger.info("Usuario obtenido exitosamente: #{inspect(user)}")
        render(conn, "profile.html", user: %{
          id: user.id,
          name: user.name,
          balance: user.balance
          # bets: get_user_bets(user_id)  # Simulamos la obtención de apuestas
        })
      {:error, reason} ->
        Logger.error("Error al obtener el usuario: #{reason}")
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end
end
