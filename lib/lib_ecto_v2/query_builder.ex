defmodule LibEctoV2.QueryBuilder do
  @moduledoc """
  查询构建器模块，提供构建和管理数据库查询条件的功能。

  此模块专注于将用户提供的过滤参数转换为 Ecto 查询条件。
  """

  import Ecto.Query

  alias LibEctoV2.Exceptions

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
      iex> LibEctoV2.QueryBuilder.build_condition(init, params, filters, filter_fn)
      {:ok, dynamic_expr}
  """
  @spec build_condition(any(), map(), list(), function(), boolean()) ::
          {:ok, any()} | {:error, any()}
  def build_condition(init, params, filters, filter_fn, check_empty? \\ true) do
    filters
    |> Enum.reduce_while({:ok, init}, fn filter, {:ok, acc} ->
      case filter_fn.(filter, acc, params) do
        {:ok, dynamic} -> {:cont, {:ok, dynamic}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> check_result(init, check_empty?)
  end

  @doc """
  检查查询条件构建的结果，并处理空条件的情况。

  ## 参数

  - `result`: 构建查询条件的结果
  - `init`: 初始查询条件
  - `check_empty?`: 是否检查空条件

  ## 返回值

  - `{:ok, dynamic}`: 有效的查询条件
  - `{:error, reason}`: 错误原因
  """
  @spec check_result({:ok, any()} | {:error, any()}, any(), boolean()) ::
          {:ok, any()} | {:error, any()}
  def check_result({:ok, dynamic}, init, check_empty?) do
    if check_empty? and dynamic == init do
      Exceptions.empty_filter()
    else
      {:ok, dynamic}
    end
  end

  def check_result({:error, reason}, _init, _check_empty?) do
    {:error, reason}
  end

  @doc """
  应用排序、限制和偏移到查询。

  ## 参数

  - `query`: Ecto 查询
  - `sort_by`: 排序选项
  - `limit`: 限制返回记录数
  - `offset`: 跳过前 N 条记录

  ## 返回值

  - 包含排序、限制和偏移的 Ecto 查询

  ## 示例

      iex> query = from(u in User)
      iex> LibEctoV2.QueryBuilder.apply_query_options(query, [desc: :inserted_at], 10, 0)
      #Ecto.Query<...>
  """
  @spec apply_query_options(
          Ecto.Query.t(),
          keyword() | nil,
          non_neg_integer() | nil,
          non_neg_integer() | nil
        ) ::
          Ecto.Query.t()
  def apply_query_options(query, sort_by, limit, offset)

  def apply_query_options(query, sort_by, limit, offset) do
    query = if sort_by, do: order_by(query, ^sort_by), else: query
    query = if limit, do: limit(query, ^limit), else: query
    query = if offset, do: offset(query, ^offset), else: query
    query
  end

  @doc """
  计算分页查询的偏移量。

  ## 参数

  - `page`: 页码（从1开始）
  - `page_size`: 每页记录数

  ## 返回值

  - 偏移量

  ## 示例

      iex> LibEctoV2.QueryBuilder.calculate_offset(2, 10)
      10
  """
  @spec calculate_offset(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  def calculate_offset(page, page_size) do
    if page == 0 do
      0
    else
      (page - 1) * page_size
    end
  end
end
