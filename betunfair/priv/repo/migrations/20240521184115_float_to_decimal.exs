defmodule Betunfair.Repo.Migrations.FloatToDecimal do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      modify :original_stake, :decimal
      modify :remaining_stake, :decimal
      modify :odds, :decimal
    end

    alter table(:matched) do
      add :matched_amount, :decimal
      add :lay_win, :decimal
      add :back_win, :decimal
    end
  end
end
