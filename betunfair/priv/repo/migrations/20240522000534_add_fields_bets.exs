defmodule Betunfair.Repo.Migrations.AddFieldsBets do
  use Ecto.Migration

  def change do
    alter table(:matched) do
      add :balance_empty_stake, :float
      add :balance_remain_stake, :float
      add :empty_stake, :string
    end
  end
end
