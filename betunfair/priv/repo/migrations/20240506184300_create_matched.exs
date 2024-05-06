defmodule Betunfair.Repo.Migrations.CreateMatched do
  use Ecto.Migration

  def change do
    create table(:matched) do
      add :id_matched, :integer
      add :id_bet_backed, references(:bets, on_delete: :nothing)
      add :id_bet_layed, references(:bets, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:matched, [:id_matched])
    create index(:matched, [:id_bet_backed])
    create index(:matched, [:id_bet_layed])
  end
end
