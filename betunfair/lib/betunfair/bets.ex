defmodule Betunfair.Bets do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bets" do
    field :id_bets, :integer
    field :odds, :integer
    field :original_stake, :integer
    field :remaining_stake, :integer
    field :type, :string
    field :user_id, :id
    field :market_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bets, attrs) do
    bets
    |> cast(attrs, [:id_bets, :odds, :type, :original_stake, :remaining_stake])
    |> validate_required([:id_bets, :odds, :type, :original_stake, :remaining_stake])
    |> unique_constraint(:id_bets)
  end
end
