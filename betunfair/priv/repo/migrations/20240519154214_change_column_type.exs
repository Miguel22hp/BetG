defmodule MyApp.Repo.Migrations.ChangeColumnType do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      modify :odds, :float
      modify :original_stake, :float
      modify :remaining_stake, :float
    end
  end
end
