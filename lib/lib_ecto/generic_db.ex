defmodule LibEcto.GenericDB do
  @moduledoc "docs/genericdb.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defmacro __using__(opts) do
    repo = Access.get(opts, :repo)
    schema = Access.get(opts, :schema)
    columns = Access.get(opts, :columns)
    filters = Access.get(opts, :filters, columns)

    quote do
      import Ecto.Changeset
      import Ecto.Query

      @repo unquote(repo)
      @columns unquote(columns)
      @filters unquote(filters)
      @schema unquote(schema)

      @type schema_t :: @schema.t()
      @type params :: %{atom() => term()}
      @type filter_t :: %{String.t() => term()}
      @type columns :: [atom()]
      @type err_t :: {:error, any()}

      @doc """
      Create a new record in the database.
      This function require schema to have a `changeset` function.

      ## Examples

          iex> Sample.DB.create_one(%{name: "test", value: "testv"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}
      """
      @spec create_one(params()) :: {:ok, schema_t()} | err_t()
      def create_one(params) do
        %@schema{}
        |> @schema.changeset(params)
        |> @repo.insert()
      end

      defp init_dynamic(), do: dynamic([m], m.removed_at == 0)

      defp build_condition(params) do
        Enum.reduce_while(@filters, {:ok, init_dynamic()}, fn filter, {:ok, acc} ->
          case apply(__MODULE__, :filter, [filter, acc, params]) do
            {:ok, dynamic} -> {:cont, {:ok, dynamic}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
      end

      @doc """
      Get one record from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_one(%{name: "test"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

      """
      @spec get_one(filter_t(), columns()) :: {:ok, schema_t() | nil} | err_t()
      def get_one(params, columns \\ @columns) do
        with {:ok, condition} <- build_condition(params) do
          query = from(m in @schema, where: ^condition, select: ^columns)

          query
          |> @repo.one()
          |> then(fn x -> {:ok, x} end)
        end
      end

      @doc """
      Force get one record from the database by your params. if not found, return 404.


      ## Examples

          iex> Sample.DB.get_one!(%{name: "not-exists"})
          {:error, 404}
      """
      @spec get_one!(filter_t(), columns()) :: {:ok, schema_t()} | err_t()
      def get_one!(params, columns \\ @columns) do
        get_one(params, columns)
        |> case do
          {:ok, nil} -> {:error, 404}
          {:ok, ret} -> {:ok, ret}
          err -> err
        end
      end

      @doc """
      Get all records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_all(%{name: "test"})
          {:ok, [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
      """
      @spec get_all(filter_t(), columns) :: {:ok, [schema_t()]} | err_t()
      def get_all(params, columns \\ @columns) do
        with {:ok, condition} <- build_condition(params) do
          query = from(m in @schema, where: ^condition, select: ^columns)

          query
          |> @repo.all()
          |> then(fn x -> {:ok, x} end)
        end
      end

      @doc """
      Get limited records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_limit(%{name: "test"}, 1, :all, [desc: :id])
          {:ok, [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
      """
      @spec get_limit(
              params :: filter_t(),
              limit :: non_neg_integer,
              columns :: columns() | :all,
              sort_by :: keyword
            ) :: {:ok, [schema_t()]} | err_t()
      def get_limit(params, limit, columns \\ @columns, sort_by \\ [asc: :id])

      def get_limit(params, limit, :all, sort_by), do: get_limit(params, limit, @columns, sort_by)

      def get_limit(params, limit, columns, sort_by) do
        with {:ok, conditions} <- build_condition(params) do
          query =
            from(m in @schema,
              where: ^conditions,
              select: ^columns,
              order_by: ^sort_by,
              limit: ^limit
            )

          {:ok, @repo.all(query)}
        end
      end

      @doc """
      Get count of records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.count(%{name: "test"})
          {:ok, 1}
      """
      @spec count(filter_t()) :: {:ok, non_neg_integer}
      def count(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions, select: count(m.id))
          {:ok, @repo.one(query)}
        end
      end

      @doc """
      Check if record exists in the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.exists?(%{name: "test"})
          true
      """
      @spec exists?(filter_t()) :: boolean
      def exists?(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions)
          @repo.exists?(query)
        end
      end

      @doc """
      Get paginate records from the database by your params, params will be converted to where condition depends on your filters.

      <b>NOTE</b>: This page start from 1, not 0.

      ## Examples

          iex> Sample.DB.get_by_page(%{name: "test"}, 1, 10)
          {:ok, %{
            list: [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
            total: 1
          }}
      """
      @spec get_by_page(
              params :: filter_t(),
              page :: non_neg_integer(),
              page_size :: non_neg_integer(),
              columns :: columns(),
              sort_by :: keyword()
            ) ::
              {:ok, %{list: [schema_t()], total: non_neg_integer()}} | err_t()
      def get_by_page(
            params,
            page,
            page_size,
            columns \\ @columns,
            sort_by \\ [desc: :inserted_at]
          )

      def get_by_page(params, page, page_size, [:all], sort_by),
        do: get_by_page(params, page, page_size, @columns, sort_by)

      def get_by_page(params, page, page_size, columns, sort_by) do
        with {:ok, conditions} <- build_condition(params) do
          offset =
            if page == 0 do
              0
            else
              (page - 1) * page_size
            end

          query1 =
            from(m in @schema,
              where: ^conditions,
              order_by: ^sort_by,
              select: ^columns,
              limit: ^page_size,
              offset: ^offset
            )

          query2 =
            from(m in @schema,
              where: ^conditions,
              order_by: ^sort_by,
              select: count(m.id)
            )

          {:ok, %{list: @repo.all(query1), total: @repo.one(query2)}}
        end
      end

      @doc """
      Update one record, you can pass attrs to determine which field you want to update.
      The record must contain primary key.

      ## Examples

          iex> {:ok, return_value} = Sample.DB.get_one(%{name: "test"})
          iex> Sample.DB.update_one(return_value, %{name: "test"})
      """
      @spec update_one(item :: schema_t(), attrs :: keyword() | %{atom() => term()}) ::
              {:ok, any()} | err_t()
      def update_one(item, attrs) do
        item
        |> change(attrs)
        |> @repo.update()
      end

      @doc """
      Delete one record. The record must contain primary key.

      ## Examples

          iex> {:ok, return_value} = Sample.DB.get_one(%{name: "test"})
          iex> Sample.DB.delete_one(return_value)
      """
      @spec delete_one(schema_t()) :: {:ok, any()} | err_t()
      def delete_one(item), do: @repo.delete(item)

      @doc """
      Delete all records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.delete_all(%{name: "test"})
      """
      @spec delete_all(filter_t()) :: {non_neg_integer(), nil | [term()]} | err_t()
      def delete_all(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions)
          @repo.delete_all(query)
        end
      end
    end
  end
end
