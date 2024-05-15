defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller
  alias Betunfair.Repo
  alias Betunfair.User  # Asegúrate de que este alias está correctamente definido

  def profile(conn, %{"id" => user_id}) do
    user = Repo.get(User, user_id)  # Aquí User debe ser el módulo Ecto, no un átomo
    case user do
      nil ->
        conn
        |> put_flash(:error, "User not found.")
        |> redirect(to: Routes.home_path(conn, :index))
      user ->
        render(conn, "profile.html", user: user)
    end
  end
end
