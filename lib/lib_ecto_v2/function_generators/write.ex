defmodule LibEctoV2.FunctionGenerators.Write do
  @moduledoc """
  写操作函数生成器模块，用于生成创建、更新和删除记录的函数。

  此模块专注于生成与数据写入相关的函数，如 `create_one/1`、`update_one/2` 和 `delete_one/1` 等。
  """

  @doc """
  生成写操作相关的函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `filters`: 过滤器列表

  ## 返回值

  - 包含写操作函数的 quoted 表达式

  ## 示例

      iex> LibEctoV2.FunctionGenerators.Write.generate_write_funcs(MyApp.User, MyApp.Repo, [:id, :name])
      quote do
        # 各种写操作函数的定义
      end
  """
  def generate_write_funcs(schema, repo, filters) do
    quote do
      # types

      @doc """
      在数据库中创建新记录。
      此函数要求 schema 有一个 `changeset` 函数。

      ## 示例

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
      更新一条记录，可以通过 attrs 参数确定要更新的字段。
      记录必须包含主键。

      ## 示例

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
      删除一条记录。记录必须包含主键。

      ## 示例

          iex> {:ok, return_value} = Sample.DB.get_one(%{"name"=> "test"})
          iex> Sample.DB.delete_one(return_value)
      """
      @spec delete_one(schema_t()) :: {:ok, any()} | err_t()
      def delete_one(item), do: unquote(repo).delete(item)

      @doc """
      根据参数从数据库中删除所有匹配的记录，参数将根据过滤器转换为查询条件。

      ## 示例

          iex> Sample.DB.delete_all(%{"name"=> "test"})
      """
      @spec delete_all(filter_t()) :: {non_neg_integer(), nil | [term()]} | err_t()
      def delete_all(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn, false) do
          query = from(m in unquote(schema), where: ^conditions)
          unquote(repo).delete_all(query)
        end
      end
    end
  end
end
