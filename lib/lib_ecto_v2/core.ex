defmodule LibEctoV2.Core do
  @moduledoc """
  LibEctoV2 的核心模块，提供基础宏和类型定义。

  此模块包含 LibEctoV2 的核心功能，特别是 `__using__` 和 `__before_compile__` 宏，
  它们负责注册必要的属性并生成 CRUD 函数。
  """

  alias LibEctoV2.FunctionGenerators

  @doc """
  使用此宏将 LibEctoV2 的功能引入到当前模块。

  此宏会注册必要的模块属性，并设置 `__before_compile__` 回调来生成 CRUD 函数。

  ## 示例

      defmodule MyApp.UserRepo do
        use LibEctoV2.Core

        @repo MyApp.Repo
        @schema MyApp.User
        @filters [:id, :name, :email]

        def init_filter, do: true

        def filter(:id, dynamic, %{"id" => id}) do
          {:ok, dynamic_and(dynamic, id: ^id)}
        end

        # ...
      end
  """
  defmacro __using__(_opts) do
    quote do
      @before_compile LibEctoV2.Core

      import Ecto.Changeset
      import Ecto.Query

      Module.register_attribute(__MODULE__, :repo, [])
      Module.register_attribute(__MODULE__, :schema, [])
      Module.register_attribute(__MODULE__, :columns, [])
      Module.register_attribute(__MODULE__, :filters, [])
    end
  end

  @doc """
  在编译时生成 CRUD 函数。

  此宏会根据模块中定义的属性（`:repo`、`:schema`、`:filters`）生成一系列数据库操作函数。
  """
  defmacro __before_compile__(env) do
    repo = Module.get_attribute(env.module, :repo)
    schema = Module.get_attribute(env.module, :schema)
    columns = schema.__schema__(:fields)
    filters = Module.get_attribute(env.module, :filters, [:id])

    FunctionGenerators.generate_all_functions(schema, repo, columns, filters)
  end

  @doc """
  动态构建 AND 条件。

  ## 参数

  - `dynamic`: 当前的动态条件
  - `conditions`: 要添加的条件

  ## 返回值

  - 包含新条件的动态表达式

  ## 示例

      iex> dynamic = true
      iex> LibEctoV2.Core.dynamic_and(dynamic, name: "test")
      #Ecto.Query.DynamicExpr<...>
  """
  defmacro dynamic_and(dynamic, conditions) do
    quote do
      dynamic([m], ^unquote(dynamic) and ^Ecto.Query.dynamic(unquote(conditions)))
    end
  end

  @doc """
  动态构建 OR 条件。

  ## 参数

  - `dynamic`: 当前的动态条件
  - `conditions`: 要添加的条件

  ## 返回值

  - 包含新条件的动态表达式

  ## 示例

      iex> dynamic = true
      iex> LibEctoV2.Core.dynamic_or(dynamic, name: "test")
      #Ecto.Query.DynamicExpr<...>
  """
  defmacro dynamic_or(dynamic, conditions) do
    quote do
      dynamic([m], ^unquote(dynamic) or ^Ecto.Query.dynamic(unquote(conditions)))
    end
  end

  @doc """
  检查值是否为空（nil 或空字符串）。

  ## 参数

  - `value`: 要检查的值

  ## 返回值

  - `true`: 如果值为空
  - `false`: 如果值不为空

  ## 示例

      iex> LibEctoV2.Core.is_empty(nil)
      true

      iex> LibEctoV2.Core.is_empty("")
      true

      iex> LibEctoV2.Core.is_empty("test")
      false
  """
  def is_empty(nil), do: true
  def is_empty(""), do: true
  def is_empty(_), do: false
end
