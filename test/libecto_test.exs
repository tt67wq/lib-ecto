defmodule LibEcto.Test do
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
    use LibEcto,
      repo: Repo,
      schema: Test.Schema,
      columns: [
        :id,
        :name,
        :value
      ],
      filters: [
        :id,
        :name
      ]

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

  setup do
    Application.put_env(:my_app, Repo, database: "tmp/test.sqlite")

    start_supervised(Repo, [])

    sql = "DROP TABLE test"
    Ecto.Adapters.SQL.query!(Repo, sql, [])

    sql =
      "CREATE TABLE test (id TEXT PRIMARY KEY, name TEXT, value TEXT, removed_at TINYINT DEFAULT 0);"

    Ecto.Adapters.SQL.query!(Repo, sql, [])

    :ok
  end

  test "create one" do
    assert {:ok, val} = Test.DB.create_one(%{name: "name1", value: "val1"})
    assert val.name == "name1"
    assert val.value == "val1"
  end

  test "get one" do
    assert {:ok, _} = Test.DB.create_one(%{name: "name2", value: "val2"})

    assert {:ok, r} = Test.DB.get_one(%{"name" => "name2"})
    assert r.name == "name2"
    assert r.value == "val2"
  end

  test "get none exists one" do
    assert {:ok, nil} = Test.DB.get_one(%{"name" => "name-not-exists"})
    assert {:error, 404} = Test.DB.get_one!(%{"name" => "name-not-exists"})
  end

  test "get with undefined filter" do
    assert_raise(RuntimeError, fn -> Test.DB.get_one(%{"undefine" => "name1"}) end)
  end

  test "get all" do
    Test.DB.create_one(%{name: "name1", value: "val1"})
    Test.DB.create_one(%{name: "name2", value: "val2"})
    assert {:ok, recs} = Test.DB.get_all(%{"name" => {"like", "name%"}})
    assert Enum.count(recs) > 0
  end

  test "get limit and count" do
    for i <- 1..10 do
      Test.DB.create_one(%{name: "name#{i}", value: "val#{i}"})
    end

    assert {:ok, recs} = Test.DB.get_limit(%{}, 10)
    assert Enum.count(recs) == 10

    recs
    |> Enum.sort_by(& &1.id)
    |> then(fn x -> assert x == recs end)

    assert {:ok, recs} = Test.DB.get_limit(%{}, 10, :all, desc: :id)

    recs
    |> Enum.sort_by(& &1.id, :desc)
    |> then(fn x -> assert x == recs end)

    assert {:ok, 10} = Test.DB.count(%{})
  end

  test "exists" do
    Test.DB.create_one(%{name: "namex", value: "val1"})
    assert Test.DB.exists?(%{"name" => "namex"})
    assert not Test.DB.exists?(%{"name" => "namey"})
  end

  test "get by page" do
    for i <- 1..10 do
      Test.DB.create_one(%{name: "name#{i}", value: "val#{i}"})
    end

    assert {:ok, %{list: recs, total: count}} = Test.DB.get_by_page(%{}, 1, 5, :all, desc: :id)
    assert Enum.count(recs) == 5
    assert count == 10
  end

  test "update one" do
    {:ok, rec} = Test.DB.create_one(%{name: "namex", value: "val1"})

    Test.DB.update_one(rec, value: "valx")
    assert {:ok, %{value: "valx"}} = Test.DB.get_one(%{"name" => "namex"})

    Test.DB.update_one(rec, %{value: "valy"})
    assert {:ok, %{value: "valy"}} = Test.DB.get_one(%{"name" => "namex"})
  end

  test "delete one" do
    {:ok, rec} = Test.DB.create_one(%{name: "namex", value: "val1"})
    assert Test.DB.exists?(%{"name" => "namex"})
    assert {:ok, _} = Test.DB.delete_one(rec)
    assert not Test.DB.exists?(%{"name" => "namex"})
  end

  test "delete all" do
    for i <- 1..10 do
      Test.DB.create_one(%{name: "name#{i}", value: "val#{i}"})
    end

    assert {10, _} = Test.DB.delete_all(%{"name" => {"like", "name%"}})
    assert {:ok, 0} = Test.DB.count(%{"name" => {"like", "name%"}})
  end
end
