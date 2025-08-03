defmodule LibEctoV2 do
  @moduledoc """
  一个轻量级的 Elixir ORM 扩展工具，帮助你快速构建数据库操作接口。

  ## 特点

  - 简化 CRUD 操作
  - 自动生成数据库操作函数
  - 灵活的过滤器机制
  - 支持分页查询
  - 与 Ecto 无缝集成

  ## 使用方法

  使用 `use LibEctoV2` 宏可以自动生成一系列数据库操作函数，如 `create_one/1`、`get_one/1`、`get_all/1` 等。

  ```elixir
  defmodule MyApp.UserRepo do
  use LibEctoV2

  @repo MyApp.Repo
  @schema MyApp.User
  @filters [:id, :name, :email]

  def init_filter, do: true

  def filter(:id, dynamic, %{"id" => id}) do
    {:ok, dynamic_and(dynamic, id: ^id)}
  end

  def filter(:name, dynamic, %{"name" => name}) do
    {:ok, dynamic_and(dynamic, name: ^name)}
  end

  def filter(:email, dynamic, %{"email" => email}) do
    {:ok, dynamic_and(dynamic, email: ^email)}
  end

  def filter(_, dynamic, _), do: {:ok, dynamic}
  end
  ```
  """

  alias LibEctoV2.QueryBuilder

  @doc """
  使用此宏将 LibEctoV2 的功能引入到当前模块。

  此宏会注册必要的模块属性，并设置 `__before_compile__` 回调来生成 CRUD 函数。

  ## 示例

      defmodule MyApp.UserRepo do
        use LibEctoV2

        @repo MyApp.Repo
        @schema MyApp.User
        @filters [:id, :name, :email]

        def init_filter, do: true

        def filter(:id, dynamic, %{"id" => id}) do
          {:ok, dynamic_and(dynamic, id: ^id)}
        end
      end
  """
  defmacro __using__(opts) do
    quote do
      use LibEctoV2.Core, unquote(opts)
    end
  end

  @doc """
  根据提供的参数和过滤器构建查询条件。

  ## 参数

  - `init`: 初始查询条件
  - `params`: 包含过滤参数的映射
  - `filters`: 过滤器列表
  - `filter_fn`: 用于应用过滤器的函数
  - `check_empty?`: 是否检查空条件，默认为 `true`

  ## 返回值

  - `{:ok, dynamic}`: 成功构建的查询条件
  - `{:error, reason}`: 发生错误时的错误原因

  ## 示例

      iex> init = true
      iex> params = %{"name" => "test"}
      iex> filters = [:name, :age]
      iex> filter_fn = &MyModule.filter/3
      iex> LibEctoV2.build_condition(init, params, filters, filter_fn)
      {:ok, dynamic_expr}
  """
  @spec build_condition(any(), map(), list(), function(), boolean()) ::
          {:ok, any()} | {:error, any()}
  def build_condition(init, params, filters, filter_fn, check_empty? \\ true) do
    QueryBuilder.build_condition(init, params, filters, filter_fn, check_empty?)
  end

  @doc """
  生成类型定义。

  ## 参数

  - `schema`: 模式模块

  ## 返回值

  - 包含类型定义的 quoted 表达式
  """
  def generate_types(schema) do
    LibEctoV2.FunctionGenerators.generate_types(schema)
  end

  @doc """
  生成写操作相关的函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `filters`: 过滤器列表

  ## 返回值

  - 包含写操作函数的 quoted 表达式
  """
  def generate_write_funcs(schema, repo, filters) do
    LibEctoV2.FunctionGenerators.Write.generate_write_funcs(schema, repo, filters)
  end

  @doc """
  生成获取单条记录的函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `columns`: 列名列表
  - `filters`: 过滤器列表

  ## 返回值

  - 包含获取单条记录函数的 quoted 表达式
  """
  def generate_get_one_funcs(schema, repo, columns, filters) do
    LibEctoV2.FunctionGenerators.Read.generate_get_one_funcs(schema, repo, columns, filters)
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
  """
  def generate_get_many_funcs(schema, repo, columns, filters) do
    LibEctoV2.FunctionGenerators.Read.generate_get_many_funcs(schema, repo, columns, filters)
  end

  @doc """
  生成其他辅助函数。

  ## 参数

  - `schema`: 模式模块
  - `repo`: 仓库模块
  - `filters`: 过滤器列表

  ## 返回值

  - 包含辅助函数的 quoted 表达式
  """
  def generate_other_funcs(schema, repo, filters) do
    LibEctoV2.FunctionGenerators.Utils.generate_other_funcs(schema, repo, filters)
  end

  @doc """
  动态构建 AND 条件。

  该方法已废弃，请使用 LibEctoV2.Core.dynamic_and/2。

  ## 参数

  - `dynamic`: 当前的动态条件
  - `conditions`: 要添加的条件

  ## 返回值

  - 包含新条件的动态表达式
  """
  defmacro dynamic_and(dynamic, conditions) do
    quote do
      require LibEctoV2.Core

      LibEctoV2.Core.dynamic_and(unquote(dynamic), unquote(conditions))
    end
  end

  @doc """
  动态构建 OR 条件。

  该方法已废弃，请使用 LibEctoV2.Core.dynamic_or/2。

  ## 参数

  - `dynamic`: 当前的动态条件
  - `conditions`: 要添加的条件

  ## 返回值

  - 包含新条件的动态表达式
  """
  defmacro dynamic_or(dynamic, conditions) do
    quote do
      require LibEctoV2.Core

      LibEctoV2.Core.dynamic_or(unquote(dynamic), unquote(conditions))
    end
  end

  @doc """
  在编译时生成 CRUD 函数。

  该方法已废弃，请使用 LibEctoV2.Core.__before_compile__/1。
  """
  defmacro __before_compile__(env) do
    quote do
      require LibEctoV2.Core

      LibEctoV2.Core.__before_compile__(unquote(Macro.escape(env)))
    end
  end
end
