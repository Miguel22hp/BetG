defmodule Betunfair.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Betunfair.Repo

  schema "users" do
    field :balance, :integer
    field :id_users, :string
    field :name, :string

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

  # API to add funds to a user's account
  def add_funds(user_id, amount) when is_integer(amount) and amount > 0 do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      changeset = changeset(user, %{balance: user.balance + amount})
      Repo.update!(changeset)
    end)
  end

  # API to remove funds from a user's account
  def remove_funds(user_id, amount) when is_integer(amount) and amount > 0 do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      if user.balance >= amount do
        changeset = changeset(user, %{balance: user.balance - amount})
        Repo.update!(changeset)
      else
        raise "Insufficient funds"
      end
    end)
  end

  # API to fetch user info
  def get_user_info(user_id) do
    Repo.get_by(User, user_id)
  end

  # API to update user's name
  def update_user_name(user_id, new_name) when is_binary(new_name) do
    Repo.transaction(fn ->
      user = Repo.get_by!(User, id_users: user_id)
      changeset = changeset(user, %{name: new_name})
      Repo.update!(changeset)
    end)
  end
end
