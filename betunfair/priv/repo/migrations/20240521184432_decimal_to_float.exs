defmodule Betunfair.Repo.Migrations.DecimalToFloat do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      modify :original_stake, :float
      modify :remaining_stake, :float
      modify :odds, :float
    end

    alter table(:matched) do
      modify :matched_amount, :float
      modify :lay_win, :float
      modify :back_win, :float
    end
  end
end
