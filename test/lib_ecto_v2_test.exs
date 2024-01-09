defmodule LibEctoV2Test do
  @moduledoc false
  use ExUnit.Case

  alias LibEcto.KsuidType

  defmodule Repo do
    @moduledoc false
    use Ecto.Repo,
      otp_app: :my_app,
      adapter: Ecto.Adapters.SQLite3
  end

  defmodule Test.Schema do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    @primary_key {:id, KsuidType, autogenerate: true}
    schema "test" do
      field(:name, :string)
      field(:value, :string)
      field(:removed_at, :integer)
    end

    def changeset(m, params) do
      cast(m, params, [:name, :value])
    end
  end

  defmodule Test.DB do
    @moduledoc false
    use LibEctoV2

    @repo Repo
    @schema Test.Schema
    @columns [:id, :name, :value]
    @filters [:id, :name]

    def filter(:id, dynamic, %{"id" => value}) when is_bitstring(value),
      do: {:ok, dynamic([m], ^dynamic and m.id == ^value)}

    def filter(:id, dynamic, %{"id" => value}) when is_list(value), do: {:ok, dynamic([m], ^dynamic and m.id in ^value)}

    def filter(:name, dynamic, %{"name" => value}) when is_bitstring(value),
      do: {:ok, dynamic([m], ^dynamic and m.name == ^value)}

    def filter(:name, dynamic, %{"name" => {"like", value}}) when is_bitstring(value),
      do: {:ok, dynamic([m], ^dynamic and like(m.name, ^value))}

    def filter(:name, dynamic, %{"name" => value}) when is_list(value),
      do: {:ok, dynamic([m], ^dynamic and m.name in ^value)}

    def filter(_, dynamic, _), do: {:ok, dynamic}

    def init_filter, do: dynamic([m], m.removed_at == 0)
  end

  setup_all do
    Application.put_env(:my_app, Repo, database: "tmp/test.sqlite")

    start_supervised(Repo, [])

    sql = "DROP TABLE test"
    Ecto.Adapters.SQL.query!(Repo, sql, [])

    sql =
      "CREATE TABLE test (id TEXT PRIMARY KEY, name TEXT, value TEXT, removed_at TINYINT DEFAULT 0);"

    Ecto.Adapters.SQL.query!(Repo, sql, [])

    :ok
  end

  test "writes" do
    # create
    assert {:ok, val} = Test.DB.create_one(%{name: "name1", value: "val1"})
    assert val.name == "name1"
    assert val.value == "val1"

    # update
    assert {:ok, _} = Test.DB.update_one(val, %{value: "val2"})
    assert {:ok, _} = Test.DB.update_one(val, value: "val3")

    assert {:ok, r} = Test.DB.get_one(%{"name" => "name1"})
    assert r.value == "val3"

    # delete
    assert {:ok, _} = Test.DB.delete_one(r)
    assert {:ok, nil} = Test.DB.get_one(%{"name" => "name1"})

    # delete all
    assert {:ok, _} = Test.DB.create_one(%{name: "name2", value: "val2"})
    assert {:ok, _} = Test.DB.create_one(%{name: "name3", value: "val3"})
    assert {:ok, _} = Test.DB.create_one(%{name: "name4", value: "val4"})

    assert {_, nil} = Test.DB.delete_all(%{"name" => {"like", "name%"}})
    assert {:ok, 0} = Test.DB.count(%{})
  end

  test "get one" do
    assert {:ok, _} = Test.DB.create_one(%{name: "name5", value: "val5"})

    assert {:ok, r} = Test.DB.get_one(%{"name" => "name5"})
    assert r.name == "name5"
    assert r.value == "val5"

    assert {:error, :"not found"} = Test.DB.fetch_one(%{"name" => "name6"})

    assert_raise RuntimeError, fn -> Test.DB.get_one!(%{"name" => "name6"}) end
  end

  test "get many" do
    assert {:ok, _} = Test.DB.create_one(%{name: "name7", value: "val7"})
    assert {:ok, _} = Test.DB.create_one(%{name: "name8", value: "val8"})
    assert {:ok, _} = Test.DB.create_one(%{name: "name9", value: "val9"})
    assert {:ok, _} = Test.DB.create_one(%{name: "name10", value: "val10"})

    assert {:ok, r} = Test.DB.get_limit(%{"name" => {"like", "name%"}}, 3, :all)
    assert length(r) == 3

    assert {:ok, %{list: r, total: total}} = Test.DB.get_by_page(%{"name" => {"like", "name%"}}, 0, 3, :all)
    assert Enum.count(r) == 3
    assert total >= 3
  end
end
