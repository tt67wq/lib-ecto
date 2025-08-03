defmodule LibEctoV2.FunctionGenerators.Read do
  @moduledoc """
  读操作函数生成器模块，用于生成查询和读取记录的函数。

  此模块专注于生成与数据读取相关的函数，如 `get_one/1`、`get_all/1` 和 `get_by_page/3` 等。
  """

  @doc """
  生成获取单条记录的函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `columns`: 列名列表
  - `filters`: 过滤器列表

  ## 返回值

  - 包含获取单条记录函数的 quoted 表达式

  ## 示例

      iex> LibEctoV2.FunctionGenerators.Read.generate_get_one_funcs(MyApp.User, MyApp.Repo, [:id, :name], [:id, :name])
      quote do
        # 获取单条记录的函数定义
      end
  """
  def generate_get_one_funcs(schema, repo, columns, filters) do
    quote do
      @doc """
      根据参数从数据库获取一条记录，参数将根据过滤器转换为查询条件。

      ## 示例

          iex> Sample.DB.get_one(%{"name"=> "test"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}

      """
      @spec get_one(filter_t(), columns_t()) :: {:ok, schema_t() | nil} | err_t()
      def get_one(params, cols \\ unquote(columns)) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions, select: ^cols)

          {:ok, unquote(repo).one(query)}
        end
      end

      @doc """
      根据参数从数据库获取一条记录，参数将根据过滤器转换为查询条件。
      如果记录不存在，则返回错误。

      ## 示例

          iex> Sample.DB.get_one(%{"name"=> "test"})
          {:ok, %Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}}
          iex> Sample.DB.get_one(%{"name"=> "not-exists"})
          {:error, %LibEcto.Exception{message: "not found", details: %{"name" => "not-exits"}}
      """
      @spec fetch_one(filter_t(), columns_t()) :: {:ok, schema_t()} | err_t()
      def fetch_one(params, cols \\ unquote(columns)) do
        params
        |> get_one(cols)
        |> case do
          {:ok, nil} -> LibEctoV2.Exceptions.not_found(params)
          {:ok, ret} -> {:ok, ret}
          err -> err
        end
      end

      @doc """
      根据参数强制获取一条记录，如果记录不存在，则抛出 LibEcto.Exception 异常。

      ## 示例

          iex> Sample.DB.get_one!(%{"name"=> "not-exists"})
          ** LibEcto.Exception (** (Exception) not found: [{"name", "not-exists"}]
      """
      @spec get_one!(filter_t(), columns_t()) :: schema_t() | err_t()
      def get_one!(params, cols \\ unquote(columns)) do
        params
        |> get_one(cols)
        |> case do
          {:ok, nil} -> raise LibEcto.Exception, message: "not found", details: params
          {:ok, ret} -> ret
          err -> err
        end
      end
    end
  end

  @doc """
  生成获取多条记录的函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `columns`: 列名列表
  - `filters`: 过滤器列表

  ## 返回值

  - 包含获取多条记录函数的 quoted 表达式

  ## 示例

      iex> LibEctoV2.FunctionGenerators.Read.generate_get_many_funcs(MyApp.User, MyApp.Repo, [:id, :name], [:id, :name])
      quote do
        # 获取多条记录的函数定义
      end
  """
  def generate_get_many_funcs(schema, repo, columns, filters) do
    quote do
      @doc """
      根据参数从数据库获取所有匹配的记录，参数将根据过滤器转换为查询条件。

      ## 示例

          iex> Sample.DB.get_all(%{"name"=> "test"})
          {:ok, [%Simple.Schema{id: "2JIebKci1ZgKenvhllJa3PMbydB", name: "test", value: "testv"}]}
      """
      @spec get_all(filter_t(), columns_t()) :: {:ok, [schema_t()]} | err_t()
      def get_all(params, cols \\ unquote(columns)) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions, select: ^cols)

          {:ok, unquote(repo).all(query)}
        end
      end

      @doc """
      根据参数从数据库获取有限数量的记录，参数将根据过滤器转换为查询条件。

      ## 示例

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

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn, false) do
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
      根据参数从数据库获取分页记录，参数将根据过滤器转换为查询条件。

      **注意**：页码从 1 开始，而不是 0。

      ## 示例

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

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn, false) do
          offset = LibEctoV2.QueryBuilder.calculate_offset(page, page_size)

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
end
