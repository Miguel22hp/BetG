defmodule Betunfair.Repo do
  use Ecto.Repo,
    otp_app: :betunfair,
    adapter: Ecto.Adapters.Postgres
end
