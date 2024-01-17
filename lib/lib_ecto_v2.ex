defmodule LibEctoV2 do
  @moduledoc __DIR__
             |> Path.join("v2.md")
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  defmacro __using__(_) do
    quote do
      import Ecto.Changeset
      import Ecto.Query

      Module.register_attribute(__MODULE__, :repo, [])
      Module.register_attribute(__MODULE__, :schema, [])
      Module.register_attribute(__MODULE__, :columns, [])
      Module.register_attribute(__MODULE__, :filters, [])

      @before_compile LibEctoV2
    end
  end

  def build_condition(init, params, filters, filter_fn, check_empty? \\ true) do
    filters
    |> Enum.reduce_while({:ok, init}, fn filter, {:ok, acc} ->
      case filter_fn.(filter, acc, params) do
        {:ok, dynamic} -> {:cont, {:ok, dynamic}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, dynamic} ->
        if check_empty? and dynamic == init do
          {:error, "You must provide at least one filter"}
        else
          {:ok, dynamic}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def generate_types(schema) do
    quote do
      @type schema_t :: unquote(schema).t()
      @type params_t :: %{atom() => term()}
      @type filter_t :: %{String.t() => term()}
      @type columns_t :: [atom()] | :all
      @type err_t :: {:error, any()}
    end
  end

  def generate_write_funcs(schema, repo, filters) do
    quote do
      # types

      @doc """
      Create a new record in the database.
      This function require schema to have a `changeset` function.

      ## Examples

          iex> Sample.DB.create_one(%{name: "test", value: "testv"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}
      """
      @spec create_one(params_t()) :: {:ok, schema_t()} | err_t()
      def create_one(params) do
        %unquote(schema){}
        |> unquote(schema).changeset(params)
        |> unquote(repo).insert()
      end

      @doc """
      Update one record, you can pass attrs to determine which field you want to update.
      The record must contain primary key.

      ## Examples

          iex> {:ok, return_value} = Sample.DB.get_one(%{"name"=> "test"})
          iex> Sample.DB.update_one(return_value, %{"name"=> "test"})
      """
      @spec update_one(item :: schema_t(), attrs :: keyword() | %{atom() => term()}) ::
              {:ok, any()} | err_t()
      def update_one(item, attrs) do
        item
        |> change(attrs)
        |> unquote(repo).update()
      end

      @doc """
      Delete one record. The record must contain primary key.

      ## Examples

          iex> {:ok, return_value} = Sample.DB.get_one(%{"name"=> "test"})
          iex> Sample.DB.delete_one(return_value)
      """
      @spec delete_one(schema_t()) :: {:ok, any()} | err_t()
      def delete_one(item), do: unquote(repo).delete(item)

      @doc """
      Delete all records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.delete_all(%{"name"=> "test"})
      """
      @spec delete_all(filter_t()) :: {non_neg_integer(), nil | [term()]} | err_t()
      def delete_all(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn, false) do
          query = from(m in unquote(schema), where: ^conditions)
          unquote(repo).delete_all(query)
        end
      end
    end
  end

  def generate_get_one_funcs(schema, repo, columns, filters) do
    quote do
      @doc """
      Get one record from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_one(%{"name"=> "test"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

      """
      @spec get_one(filter_t(), columns_t()) :: {:ok, schema_t() | nil} | err_t()
      def get_one(params, cols \\ unquote(columns)) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions, select: ^cols)

          {:ok, unquote(repo).one(query)}
        end
      end

      @doc """
      fetch one record from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_one(%{"name"=> "test"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}
          iex> Sample.DB.get_one(%{"name"=> "not-exists"})
          {:error, "not found"}
      """
      @spec fetch_one(filter_t(), columns_t()) :: {:ok, schema_t()} | err_t()
      def fetch_one(params, cols \\ unquote(columns)) do
        params
        |> get_one(cols)
        |> case do
          {:ok, nil} -> {:error, :"not found"}
          {:ok, ret} -> {:ok, ret}
          err -> err
        end
      end

      @doc """
      Force get one record from the database by your params. if not found, return 404.


      ## Examples

          iex> Sample.DB.get_one!(%{"name"=> "not-exists"})
          ** (RuntimeError) not found
      """
      @spec get_one!(filter_t(), columns_t()) :: {:ok, schema_t()} | err_t()
      def get_one!(params, cols \\ @columns) do
        params
        |> get_one(cols)
        |> case do
          {:ok, nil} -> raise "not found"
          {:ok, ret} -> {:ok, ret}
          err -> err
        end
      end
    end
  end

  def generate_get_many_funcs(schema, repo, columns, filters) do
    quote do
      @doc """
      Get all records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_all(%{"name"=> "test"})
          {:ok, [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
      """
      @spec get_all(filter_t(), columns_t()) :: {:ok, [schema_t()]} | err_t()
      def get_all(params, cols \\ unquote(columns)) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions, select: ^cols)

          {:ok, unquote(repo).all(query)}
        end
      end

      @doc """
      Get limited records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.get_limit(%{"name"=> "test"}, 1, :all, [desc: :id])
          {:ok, [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
      """
      @spec get_limit(
              params :: filter_t(),
              limit :: non_neg_integer(),
              columns :: columns_t(),
              sort_by :: keyword()
            ) :: {:ok, [schema_t()]} | err_t()
      def get_limit(params, limit, columns \\ unquote(columns), sort_by \\ [asc: :id])

      def get_limit(params, limit, :all, sort_by), do: get_limit(params, limit, unquote(columns), sort_by)

      def get_limit(params, limit, columns, sort_by) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn, false) do
          query =
            from(m in unquote(schema),
              where: ^conditions,
              select: ^columns,
              order_by: ^sort_by,
              limit: ^limit
            )

          {:ok, unquote(repo).all(query)}
        end
      end

      @doc """
      Get paginate records from the database by your params, params will be converted to where condition depends on your filters.

      <b>NOTE</b>: This page start from 1, not 0.

      ## Examples

          iex> Sample.DB.get_by_page(%{"name"=> "test"}, 1, 10)
          {:ok, %{
            list: [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
            total: 1
          }}
      """
      @spec get_by_page(
              params :: filter_t(),
              page :: non_neg_integer(),
              page_size :: non_neg_integer(),
              columns :: columns_t(),
              sort_by :: keyword()
            ) ::
              {:ok, %{list: [schema_t()], total: non_neg_integer()}} | err_t()
      def get_by_page(params, page, page_size, columns \\ unquote(columns), sort_by \\ [desc: :id])

      def get_by_page(params, page, page_size, :all, sort_by),
        do: get_by_page(params, page, page_size, unquote(columns), sort_by)

      def get_by_page(params, page, page_size, columns, sort_by) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn, false) do
          offset =
            if page == 0 do
              0
            else
              (page - 1) * page_size
            end

          query1 =
            from(m in unquote(schema),
              where: ^conditions,
              order_by: ^sort_by,
              select: ^columns,
              limit: ^page_size,
              offset: ^offset
            )

          query2 =
            from(m in unquote(schema),
              where: ^conditions,
              order_by: ^sort_by,
              select: count(m.id)
            )

          {:ok, %{list: unquote(repo).all(query1), total: unquote(repo).one(query2)}}
        end
      end
    end
  end

  def generate_other_funcs(schema, repo, filters) do
    quote do
      @doc """
      Check if record exists in the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.exists?(%{"name"=> "test"})
          true
      """
      @spec exists?(filter_t()) :: boolean
      def exists?(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions)
          unquote(repo).exists?(query)
        end
      end

      @doc """
      Get count of records from the database by your params, params will be converted to where condition depends on your filters.

      ## Examples

          iex> Sample.DB.count(%{"name"=> "test"})
          {:ok, 1}
      """
      @spec count(filter_t()) :: {:ok, non_neg_integer}
      def count(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.build_condition(init, params, unquote(filters), filter_fn, false) do
          query = from(m in @schema, where: ^conditions, select: count(m.id))
          {:ok, unquote(repo).one(query)}
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    repo = Module.get_attribute(env.module, :repo)
    schema = Module.get_attribute(env.module, :schema)
    columns = Module.get_attribute(env.module, :columns)
    filters = Module.get_attribute(env.module, :filters, [:id])

    a = generate_types(schema)
    b = generate_write_funcs(schema, repo, filters)
    c = generate_get_one_funcs(schema, repo, columns, filters)
    d = generate_get_many_funcs(schema, repo, columns, filters)
    e = generate_other_funcs(schema, repo, filters)

    [a, b, c, d, e]
  end
end
