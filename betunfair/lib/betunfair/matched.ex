defmodule Betunfair.Matched do
  use Ecto.Schema
  import Ecto.Changeset

  schema "matched" do

    field :id_bet_backed, :id
    field :id_bet_layed, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(matched, attrs) do
    matched
    |> cast(attrs, [])
    |> validate_required([])
  end
end
