defmodule LibEctoV2.FunctionGenerators.Utils do
  @moduledoc """
  工具函数生成器模块，用于生成辅助性的数据库操作函数。

  此模块专注于生成与数据库操作相关的辅助函数，如 `exists?/1` 和 `count/1` 等。
  """

  @doc """
  生成其他辅助函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `filters`: 过滤器列表

  ## 返回值

  - 包含辅助函数的 quoted 表达式

  ## 示例

      iex> LibEctoV2.FunctionGenerators.Utils.generate_other_funcs(MyApp.User, MyApp.Repo, [:id, :name])
      quote do
        # 各种辅助函数的定义
      end
  """
  def generate_other_funcs(schema, repo, filters) do
    quote do
      @doc """
      检查数据库中是否存在符合条件的记录，参数将根据过滤器转换为查询条件。

      ## 示例

          iex> Sample.DB.exists?(%{"name"=> "test"})
          true
      """
      @spec exists?(filter_t()) :: boolean
      def exists?(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn) do
          query = from(m in unquote(schema), where: ^conditions)
          unquote(repo).exists?(query)
        end
      end

      @doc """
      获取符合条件的记录数量，参数将根据过滤器转换为查询条件。

      ## 示例

          iex> Sample.DB.count(%{"name"=> "test"})
          {:ok, 1}
      """
      @spec count(filter_t()) :: {:ok, non_neg_integer}
      def count(params) do
        init = apply(__MODULE__, :init_filter, [])
        filter_fn = &apply(__MODULE__, :filter, [&1, &2, &3])

        with {:ok, conditions} <- LibEctoV2.QueryBuilder.build_condition(init, params, unquote(filters), filter_fn, false) do
          query = from(m in @schema, where: ^conditions, select: count(m.id))
          {:ok, unquote(repo).one(query)}
        end
      end
    end
  end
end
