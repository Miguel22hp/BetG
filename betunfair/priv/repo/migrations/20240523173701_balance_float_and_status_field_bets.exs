defmodule Betunfair.Repo.Migrations.BalanceFloatAndStatusFieldBets do
  use Ecto.Migration

  def change do
    alter table(:bets) do
      add :status, :string, default: "active"
    end
    alter table(:user) do
      modify :balance, :float, default: 0.0
    end
  end
end
