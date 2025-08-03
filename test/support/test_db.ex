defmodule LibEctoV2.Test.DB do
  @moduledoc """
  测试数据库模块，用于测试 LibEctoV2 的功能。

  此模块使用 LibEctoV2 并定义了所需的回调函数。
  """

  use LibEctoV2

  @repo LibEctoV2.Test.Repo
  @schema LibEctoV2.Test.Schema
  @filters [:id, :name, :value]

  @doc """
  初始化过滤器条件，返回 true 作为初始条件。
  """
  def init_filter, do: true

  # 根据 ID 筛选记录
  def filter(:id, dynamic, %{"id" => id}) do
    import Ecto.Query

    {:ok, dynamic([m], ^dynamic and m.id == ^id)}
  end

  # 根据名称筛选记录
  def filter(:name, dynamic, %{"name" => name}) do
    import Ecto.Query

    {:ok, dynamic([m], ^dynamic and m.name == ^name)}
  end

  # 根据值筛选记录
  def filter(:value, dynamic, %{"value" => value}) do
    import Ecto.Query

    {:ok, dynamic([m], ^dynamic and m.value == ^value)}
  end

  @doc """
  处理没有匹配的过滤器情况。
  """
  def filter(_, dynamic, _), do: {:ok, dynamic}
end
