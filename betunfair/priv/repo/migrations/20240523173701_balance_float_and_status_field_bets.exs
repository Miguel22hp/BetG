defmodule Betunfair.Repo.Migrations.BalanceFloatAndStatusFieldBets do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      add :status, :string, default: "active"
    end
    alter table(:users) do
      modify :balance, :float, default: 0.0
    end
    alter table(:matched) do
      remove :lay_win
      remove :back_win
    end
  end
end
