defmodule LibEctoV2.Exceptions do
  @moduledoc """
  异常定义模块，用于处理 LibEctoV2 中的错误和异常。

  此模块重用了 `LibEcto.Exception` 的功能，并提供额外的错误处理工具。
  """

  @doc """
  返回 LibEcto.Exception 实例，保持与现有代码的兼容性。

  ## 参数

  - `message`: 错误消息
  - `details`: 可选的错误详情

  ## 示例

      iex> LibEctoV2.Exceptions.new("记录未找到", %{id: 123})
      %LibEcto.Exception{message: "记录未找到", details: %{id: 123}}
  """
  @spec new(String.t() | nil, any()) :: LibEcto.Exception.t()
  def new(message, details \\ nil) do
    LibEcto.Exception.new(message, details)
  end

  @doc """
  处理数据库查询时的"not found"错误，返回标准化的错误格式。

  ## 参数

  - `params`: 查询参数，用于错误详情

  ## 返回值

  - `{:error, %LibEcto.Exception{}}`: 包含错误信息的元组

  ## 示例

      iex> LibEctoV2.Exceptions.not_found(%{"id" => 123})
      {:error, %LibEcto.Exception{message: "not found", details: %{"id" => 123}}}
  """
  @spec not_found(map()) :: {:error, LibEcto.Exception.t()}
  def not_found(params) do
    {:error, new("not found", params)}
  end

  @doc """
  处理筛选条件为空的错误情况。

  ## 返回值

  - `{:error, String.t()}`: 包含错误信息的元组

  ## 示例

      iex> LibEctoV2.Exceptions.empty_filter()
      {:error, "You must provide at least one filter"}
  """
  @spec empty_filter() :: {:error, String.t()}
  def empty_filter do
    {:error, "You must provide at least one filter"}
  end
end
