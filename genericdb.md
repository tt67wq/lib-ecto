
<!-- MDOC !-->
Simple wrapper for ecto, provide query/insert/update/drop method for daily use.



## Example
```Elixir
## define a schema
defmodule Sample.Schema do
  use Ecto.Schema
  import Ecto.Changeset

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

defmodule Sample.DB do
    use LibEcto.GenericDB
      repo: Sample.Repo,
      schema: Sample.Schema,
      columns: [
        :id,
        :name,
        :value
      ],
      filters: [
        :name
      ]

    def filter(:name, dynamic, %{"name" => value}) when is_bitstring(value),
    do: {:ok, dynamic([m], ^dynamic and m.name == ^value)}

    def filter(:name, dynamic, %{"name" => value}) when is_list(value),
    do: {:ok, dynamic([m], ^dynamic and m.name in ^value)}

    def filter(_, dynamic, _), do: {:ok, dynamic}
end
```

now we can do insert/query/update/delete action with Sample.DB:

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