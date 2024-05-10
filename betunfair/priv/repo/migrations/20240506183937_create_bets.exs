defmodule Betunfair.Repo.Migrations.CreateBets do
  use Ecto.Migration

  def change do
    create table(:bets) do
      add :odds, :integer
      add :type, :string
      add :original_stake, :integer
      add :remaining_stake, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :market_id, references(:markets, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:bets, [:user_id])
    create index(:bets, [:market_id])
  end
end
