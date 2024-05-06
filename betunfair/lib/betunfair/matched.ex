defmodule Betunfair.Matched do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matched" do
    field :id_matched, :integer
    field :id_bet_backed, :id
    field :id_bet_layed, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(matched, attrs) do
    matched
    |> cast(attrs, [:id_matched])
    |> validate_required([:id_matched])
    |> unique_constraint(:id_matched)
  end
end
