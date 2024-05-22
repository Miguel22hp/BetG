defmodule BetunfairWeb.Router do
  use BetunfairWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BetunfairWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BetunfairWeb do
    pipe_through :browser

    get "/", PageController, :home

    get "/users/:id/profile", ProfileController, :profile
    post "/add_funds", ProfileController, :add_funds
    post "/remove_funds", ProfileController, :withdraw_funds

    get "/bets", BetsController, :bets
    post "/bets/load_bets", BetsController, :load_bets
    post "/bets/back_bet", BetsController, :back_bet
    post "/bets/lay_bet", BetsController, :lay_bet
  end

  # Other scopes may use custom stacks.
  # scope "/api", BetunfairWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:betunfair, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BetunfairWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
