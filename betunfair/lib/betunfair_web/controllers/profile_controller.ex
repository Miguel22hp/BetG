defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller
  alias Betunfair.User.OperationsUser  # Alias the OperationsUser module

  def profile(conn, %{"id" => user_id}) do
    case OperationsUser.user_get(user_id) do
      {:ok, user} ->
        render(conn, "profile.html", user: user)
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
    end
  end
end
