defmodule LibEctoV2.FunctionGenerators do
  @moduledoc """
  函数生成器模块，用于生成数据库操作相关的函数。

  此模块作为其他生成器子模块的入口点，提供了类型定义和函数生成的统一接口。
  """

  alias LibEctoV2.FunctionGenerators.Read
  alias LibEctoV2.FunctionGenerators.Utils
  alias LibEctoV2.FunctionGenerators.Write

  @doc """
  生成类型定义。

  ## 参数

  - `schema`: 模式模块

  ## 返回值

  - 包含类型定义的 quoted 表达式

  ## 示例

      iex> LibEctoV2.FunctionGenerators.generate_types(MyApp.User)
      quote do
        @type schema_t :: MyApp.User.t()
        @type params_t :: %{atom() => term()}
        # ...
      end
  """
  def generate_types(schema) do
    quote do
      @type schema_t :: unquote(schema).t()
      @type params_t :: %{atom() => term()}
      @type filter_t :: %{String.t() => term()}
      @type columns_t :: [atom()] | :all
      @type err_t :: {:error, any()}
    end
  end

  @doc """
  生成所有 CRUD 函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `columns`: 列名列表
  - `filters`: 过滤器列表

  ## 返回值

  - 包含所有生成函数的 quoted 表达式列表

  ## 示例

      iex> LibEctoV2.FunctionGenerators.generate_all_functions(MyApp.User, MyApp.Repo, [:id, :name], [:id, :name])
      [quoted_expr1, quoted_expr2, ...]
  """
  def generate_all_functions(schema, repo, columns, filters) do
    [
      generate_types(schema),
      Write.generate_write_funcs(schema, repo, filters),
      Read.generate_get_one_funcs(schema, repo, columns, filters),
      Read.generate_get_many_funcs(schema, repo, columns, filters),
      Utils.generate_other_funcs(schema, repo, filters)
    ]
  end
end
