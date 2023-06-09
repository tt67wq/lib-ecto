defmodule LibEcto.GenericDB do
  @moduledoc "genericdb.md"
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

      alias Ecto.Multi

      @repo unquote(repo)
      @columns unquote(columns)
      @filters unquote(filters)
      @schema unquote(schema)

      @type schema_t :: @schema.t()
      @type err_t :: {:error, any()}

      @spec create_one(map()) :: {:ok, schema_t()} | err_t()
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

      @spec get_one(map(), [atom()]) :: {:ok, schema_t() | nil} | err_t()
      def get_one(params, columns \\ @columns) do
        with {:ok, condition} <- build_condition(params) do
          query = from(m in @schema, where: ^condition, select: ^columns)

          query
          |> @repo.one()
          |> then(fn x -> {:ok, x} end)
        end
      end

      @spec get_one!(map(), [atom()]) :: {:ok, schema_t()} | err_t()
      def get_one!(params, columns \\ @columns) do
        get_one(params, columns)
        |> case do
          {:ok, nil} -> {:error, 404}
          {:ok, ret} -> {:ok, ret}
          err -> err
        end
      end

      @spec get_all(map(), [atom()]) :: {:ok, [schema_t()]} | err_t()
      def get_all(params, columns \\ @columns) do
        with {:ok, condition} <- build_condition(params) do
          query = from(m in @schema, where: ^condition, select: ^columns)

          query
          |> @repo.all()
          |> then(fn x -> {:ok, x} end)
        end
      end

      @spec get_limit(
              params :: %{String.t() => term()},
              limit :: non_neg_integer,
              columns :: [atom] | :all,
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

      @spec count(%{String.t() => term()}) :: {:ok, non_neg_integer}
      def count(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions, select: count(m.id))
          {:ok, @repo.one(query)}
        end
      end

      @spec exists?(%{String.t() => term()}) :: boolean
      def exists?(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions)
          @repo.exists?(query)
        end
      end

      @spec get_by_page(map(), integer, integer, [atom()], keyword) ::
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

      @spec update_one(schema_t(), keyword() | %{atom() => term()}) :: {:ok, any()} | err_t()
      def update_one(item, attrs) do
        item
        |> change(attrs)
        |> @repo.update()
      end

      @spec drop_one(schema_t()) :: {:ok, any()} | err_t()
      def drop_one(item),
        do: update_one(item, removed_at: :os.system_time(:milli_seconds))

      @spec delete_one(schema_t()) :: {:ok, any()} | err_t()
      def delete_one(item), do: @repo.delete(item)

      @spec delete_all(%{bitstring() => term()}) :: {non_neg_integer(), nil | [term()]} | err_t()
      def delete_all(params) do
        with {:ok, conditions} <- build_condition(params) do
          query = from(m in @schema, where: ^conditions)
          @repo.delete_all(query)
        end
      end
    end
  end
end
