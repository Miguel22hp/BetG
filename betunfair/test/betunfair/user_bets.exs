defmodule Betunfair.UserTest do
  use Betunfair.DataCase, async: true

  setup do
    Betunfair.User.SupervisorUser.start_link()

    Ecto.Adapters.SQL.Sandbox.checkout(Betunfair.Repo)
    # Permitir la conexión de sandbox para el proceso del GenServer
    Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), :user_gestor)

    :ok
  end


  describe "User Creation" do
    test "create a user" do
      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      assert {:ok, user_id+1} == Betunfair.User.GestorUser.user_create("2", "User 2")
      assert {:ok, user_id+2} == Betunfair.User.GestorUser.user_create("3", "User 3")

    end

    test "user get data " do
      {:ok, id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name = :"user_#{id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)
      user = Betunfair.User.OperationsUser.user_get(id)
      assert user == {:ok, %{name: "User 1",id: "1",balance: 0.0}}
    end

    test "create a user with the same id" do
      Betunfair.User.GestorUser.user_create("1", "User 1") == {:ok, 1}
      assert Betunfair.User.GestorUser.user_create("1", "User 1") == {:error, "A user with the same ID already exists"}
    end
  end


end
