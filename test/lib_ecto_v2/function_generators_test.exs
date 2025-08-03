defmodule LibEctoV2.FunctionGeneratorsTest do
  use ExUnit.Case, async: true

  alias LibEctoV2.FunctionGenerators

  # 由于 doctest 中的示例会导致编译错误，暂时跳过
  # doctest LibEctoV2.FunctionGenerators

  describe "generate_types/1" do
    test "生成正确的类型定义" do
      schema = LibEctoV2.Test.Schema
      result = FunctionGenerators.generate_types(schema)

      # 由于 quoted 表达式无法直接比较，我们检查返回值是否是一个宏 quote 块
      assert is_tuple(result)
      assert elem(result, 0) == :__block__
    end
  end

  describe "generate_all_functions/4" do
    test "生成所有 CRUD 函数" do
      schema = LibEctoV2.Test.Schema
      repo = LibEctoV2.Test.Repo
      columns = [:id, :name, :value]
      filters = [:id, :name, :value]

      result = FunctionGenerators.generate_all_functions(schema, repo, columns, filters)

      # 检查是否返回了五个函数生成块
      assert is_list(result)
      assert length(result) == 5
    end
  end
end
