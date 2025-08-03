defmodule LibEctoV2.CoreTest do
  use ExUnit.Case, async: true

  alias LibEctoV2.Core

  # 由于宏测试需要在编译时运行，暂时跳过 doctest
  # doctest LibEctoV2.Core

  describe "is_empty/1" do
    test "nil 被认为是空的" do
      assert Core.is_empty(nil)
    end

    test "空字符串被认为是空的" do
      assert Core.is_empty("")
    end

    test "非空值不是空的" do
      refute Core.is_empty("test")
      refute Core.is_empty(123)
      refute Core.is_empty(%{})
      refute Core.is_empty([])
    end
  end
end
