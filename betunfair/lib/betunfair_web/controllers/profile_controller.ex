defmodule BetunfairWeb.ProfileController do
  use BetunfairWeb, :controller

  def profile(conn, _params) do
    render(conn, :profile)
  end
end
