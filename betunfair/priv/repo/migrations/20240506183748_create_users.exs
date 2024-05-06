defmodule Betunfair.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_identifier, :integer
      add :id_users, :string
      add :balance, :integer
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:id_users])
    create unique_index(:users, [:user_identifier])
  end
end
