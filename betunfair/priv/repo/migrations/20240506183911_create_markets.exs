defmodule Betunfair.Repo.Migrations.CreateMarkets do
  use Ecto.Migration

  def change do
    create table(:markets) do
      add :id_markets, :integer
      add :name, :string
      add :description, :string
      add :status, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:markets, [:id_markets])
  end
end
