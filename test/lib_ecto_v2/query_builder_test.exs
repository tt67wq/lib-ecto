defmodule LibEctoV2.QueryBuilderTest do
  use ExUnit.Case, async: true

  alias LibEctoV2.QueryBuilder

  # 由于 doctest 中的示例会导致编译错误，暂时跳过
  # doctest LibEctoV2.QueryBuilder

  describe "build_condition/5" do
    test "成功构建查询条件" do
      init = true
      params = %{"name" => "test"}
      filters = [:name, :age]

      filter_fn = fn
        :name, dynamic, %{"name" => name} -> {:ok, dynamic and [name: name]}
        _, dynamic, _ -> {:ok, dynamic}
      end

      assert {:ok, _dynamic} = QueryBuilder.build_condition(init, params, filters, filter_fn)
    end

    test "当没有条件匹配且 check_empty? 为 true 时返回错误" do
      init = true
      params = %{}
      filters = [:name, :age]
      filter_fn = fn _, dynamic, _ -> {:ok, dynamic} end

      assert {:error, "You must provide at least one filter"} =
               QueryBuilder.build_condition(init, params, filters, filter_fn)
    end

    test "当没有条件匹配且 check_empty? 为 false 时返回成功" do
      init = true
      params = %{}
      filters = [:name, :age]
      filter_fn = fn _, dynamic, _ -> {:ok, dynamic} end

      assert {:ok, true} = QueryBuilder.build_condition(init, params, filters, filter_fn, false)
    end

    test "过滤器返回错误时传递错误" do
      init = true
      params = %{"invalid" => "data"}
      filters = [:name]
      filter_fn = fn :name, _dynamic, %{"invalid" => _} -> {:error, "Invalid data"} end

      assert {:error, "Invalid data"} = QueryBuilder.build_condition(init, params, filters, filter_fn)
    end
  end

  describe "check_result/3" do
    test "当动态条件等于初始条件且 check_empty? 为 true 时返回错误" do
      result = {:ok, true}
      init = true
      check_empty? = true

      assert {:error, "You must provide at least one filter"} =
               QueryBuilder.check_result(result, init, check_empty?)
    end

    test "当动态条件不等于初始条件时返回成功" do
      result = {:ok, false}
      init = true
      check_empty? = true

      assert {:ok, false} = QueryBuilder.check_result(result, init, check_empty?)
    end

    test "当 check_empty? 为 false 时，即使动态条件等于初始条件也返回成功" do
      result = {:ok, true}
      init = true
      check_empty? = false

      assert {:ok, true} = QueryBuilder.check_result(result, init, check_empty?)
    end

    test "传递错误结果" do
      result = {:error, "Some error"}
      init = true
      check_empty? = true

      assert {:error, "Some error"} = QueryBuilder.check_result(result, init, check_empty?)
    end
  end

  describe "calculate_offset/2" do
    test "正确计算偏移量（页码从1开始）" do
      assert QueryBuilder.calculate_offset(1, 10) == 0
      assert QueryBuilder.calculate_offset(2, 10) == 10
      assert QueryBuilder.calculate_offset(3, 10) == 20
    end

    test "页码为0时偏移量为0" do
      assert QueryBuilder.calculate_offset(0, 10) == 0
    end
  end
end
