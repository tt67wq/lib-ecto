defmodule LibEctoV2.Test.Repo do
  @moduledoc """
  测试用的 Repo 模块，模拟 Ecto.Repo 的行为。
  """

  # 以下函数用于测试，实际不执行数据库操作
  # 我们不使用 use Ecto.Repo 以避免冲突

  def all(_query, _opts \\ []) do
    # 所有的查询返回完整的记录列表
    [
      %LibEctoV2.Test.Schema{id: "1", name: "test1", value: "value1"},
      %LibEctoV2.Test.Schema{id: "2", name: "test2", value: "value2"}
    ]
  end

  def get(_, _, _opts \\ []) do
    %LibEctoV2.Test.Schema{id: "1", name: "test1", value: "value1"}
  end

  def get_by(_, _, _opts \\ []) do
    %LibEctoV2.Test.Schema{id: "1", name: "test1", value: "value1"}
  end

  def one(query, _opts \\ []) do
    # 检查查询是否包含 count 函数
    # 如果是 count 查询，返回数字
    if inspect(query) =~ "count" do
      2
    else
      # 否则返回一条记录
      %LibEctoV2.Test.Schema{id: "1", name: "test1", value: "value1"}
    end
  end

  def insert(_changeset, _opts \\ []) do
    {:ok, %LibEctoV2.Test.Schema{id: "3", name: "new", value: "new_value"}}
  end

  def update(_changeset, _opts \\ []) do
    {:ok, %LibEctoV2.Test.Schema{id: "1", name: "updated", value: "value1"}}
  end

  def delete(_schema, _opts \\ []) do
    {:ok, %LibEctoV2.Test.Schema{id: "1", name: "test1", value: "value1"}}
  end

  def delete_all(_query, _opts \\ []) do
    {2, nil}
  end

  def exists?(_query, _opts \\ []) do
    true
  end
end
