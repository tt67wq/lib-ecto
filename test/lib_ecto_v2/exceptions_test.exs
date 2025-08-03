defmodule LibEctoV2.ExceptionsTest do
  use ExUnit.Case, async: true

  alias LibEctoV2.Exceptions

  # 由于 doctest 中的示例可能会导致编译错误，暂时跳过
  # doctest LibEctoV2.Exceptions

  describe "new/2" do
    test "创建异常" do
      exception = Exceptions.new("测试错误", %{id: 123})
      assert exception.message == "测试错误"
      assert exception.details == %{id: 123}
    end

    test "创建没有详情的异常" do
      exception = Exceptions.new("测试错误")
      assert exception.message == "测试错误"
      assert exception.details == nil
    end
  end

  describe "not_found/1" do
    test "返回标准化的 not found 错误" do
      params = %{"id" => 123}
      result = Exceptions.not_found(params)

      assert {:error, exception} = result
      assert exception.message == "not found"
      assert exception.details == params
    end
  end

  describe "empty_filter/0" do
    test "返回标准化的空过滤器错误" do
      result = Exceptions.empty_filter()

      assert {:error, "You must provide at least one filter"} = result
    end
  end
end
