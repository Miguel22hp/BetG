defmodule Betunfair.Repo.Migrations.ChangeStakes do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      modify :original_stake, :decimal
      modify :remaining_stake, :decimal
      modify :odds, :decimal
    end

    alter table(:bets) do
      modify :original_stake, :decimal
      modify :remaining_stake, :decimal
      modify :odds, :decimal
    end
  end
end
