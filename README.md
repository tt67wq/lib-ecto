<!-- MDOC !-->
LibEcto is a simple wrapper for [ecto](https://hexdocs.pm/ecto/Ecto.html), make it much easier for daily use.

## Why LibEcto

Ecto is a great library, but it's a little bit verbose for daily use.

For example, imaging you have a schema like this:

```Elixir
defmodule Sample.Schema do
  use Ecto.Schema

  @primary_key {:id, EctoKsuid, autogenerate: true}
  schema "test" do
    field :name, :string
    field :value, :string

    timestamps()
  end

  def changeset(m, params) do
    m
    |> cast(params, [:name, :value])
  end
end
```

For most common use case, you need to write a lot of boilerplate code to do simple CRUD operation:

```Elixir
defmodule Sample.DB do

  alias Sample.Schema
  alias Sample.Repo
  import Ecto.Changeset

  def insert_one(params) do
    Schema.changeset(%Schema{}, params)
    |> Repo.insert()
  end

  def update_one(m, params) do
    m
    |> change(params)
    |> Repo.update()
  end

  def delete_one(m) do
    Repo.delete(m)
  end


  def get_by_id(id) do
    Repo.get(Schema, id, select: [:id, :name, :value])
  end

  def get_by_id_array(id_array) do
    Repo.all(from m in Schema, where: m.id in ^id_array, select: [:id, :name, :value])
  end

  def get_by_name(name) do
    Repo.get_by(Schema, name: name, select: [:id, :name, :value])
  end

  #... more boilerplate code
  # - get by name array
  # - get by page
  # - get by prefix

end
```

But!!!!!! With LibEcto, you can code like this:

```Elixir
defmodule Sample.DB do
    use LibEcto
      repo: Sample.Repo,
      schema: Sample.Schema,
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

    def filter(:id, dynamic, %{"id" => value}) when is_list(value),
      do: {:ok, dynamic([m], ^dynamic and m.id in ^value)}

    def filter(:name, dynamic, %{"name" => value}) when is_bitstring(value),
      do: {:ok, dynamic([m], ^dynamic and m.name == ^value)}

    def filter(:name, dynamic, %{"name" => {"like", value}}) when is_bitstring(value),
      do: {:ok, dynamic([m], ^dynamic and like(m.name, value))}

    def filter(:name, dynamic, %{"name" => value}) when is_list(value),
      do: {:ok, dynamic([m], ^dynamic and m.name in ^value)}

    def filter(_, dynamic, _), do: {:ok, dynamic}


    # you can use ecto's ability to build complicate query or update or transaction if GenericDB can't satisfy your need
    def other_complicated_query_or_update() do
      # do something
    end
end
```

LibEcto will generate all the boilerplate code for you, and you can focus on your business logic:


```Elixir
iex> Sample.DB.create_one(%{name: "test", value: "testv"})
{:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

iex> Sample.DB.get_one(%{name: "test"})
{:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

iex> Sample.DB.get_one(%{name: "not-exists"})
{:ok, nil}

iex> Sample.DB.get_one!(%{name: "not-exists"})
{:error, 404}

iex> {:ok, m} = Sample.DB.get_one(%{name: "test"})
iex> Sample.DB.update_one(m, name: "test2")
{:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test2", value: "testv"}}
```

## Installation

The package can be installed by adding `lib_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lib_ecto, "~> 0.1.0"}
  ]
end
```