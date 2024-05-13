defmodule Betunfair.Bet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :odds, :integer
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :type, :string
    field :user_id, :id
    field :market_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bet, attrs) do
    bet
    |> cast(attrs, [:odds, :type, :original_stake, :remaining_stake])
    |> validate_required([:odds, :type, :original_stake, :remaining_stake])
  end
end
