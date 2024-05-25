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


  describe "User deposit Operation" do

    test "deposit a user", context do
      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)


      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 0.0}}
      assert Betunfair.User.OperationsUser.user_deposit(user_id, 100.0) == :ok
      assert Betunfair.User.OperationsUser.user_get(user_id) == {:ok, %{name: "User 1",id: "1",balance: 100.0}}
    end

    test "deposit in a non existing user" do
      assert Betunfair.User.OperationsUser.user_deposit(1, 100.0) == {:error, "User was not found"}
    end

    test "deposit a negative number in your account" do
      {:ok, user_id} = Betunfair.User.GestorUser.user_create("1", "User 1")
      process_name = :"user_#{user_id}" # Construye el átomo correctamente
      Ecto.Adapters.SQL.Sandbox.allow(Betunfair.Repo, self(), process_name)

      assert Betunfair.User.OperationsUser.user_deposit(user_id, -100.0) ==  {:error, "The amount you need to deposit must be greater than 0"}

    end

  end


end
