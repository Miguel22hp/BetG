defmodule BetunfairWeb.BetsController do
  use BetunfairWeb, :controller

  def bets(conn, _params) do
    render(conn, :bets)
  end
end
