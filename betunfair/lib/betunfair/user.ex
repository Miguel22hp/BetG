defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :balance, :integer
    field :id_users, :string
    field :name, :string
    field :user_identifier, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_identifier, :id_users, :balance, :name])
    |> validate_required([:user_identifier, :id_users, :balance, :name])
    |> unique_constraint(:id_users)
    |> unique_constraint(:user_identifier)
  end
end
