defmodule Betunfair.Markets do
  use Ecto.Schema
  import Ecto.Changeset

  schema "markets" do
    field :description, :string
    field :id_markets, :integer
    field :name, :string
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(markets, attrs) do
    markets
    |> cast(attrs, [:id_markets, :name, :description, :status])
    |> validate_required([:id_markets, :name, :description, :status])
    |> unique_constraint(:id_markets)
  end
end
