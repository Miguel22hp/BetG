defmodule Betunfair.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :id_users, :string
      add :balance, :float
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:id_users])
  end
end
