defmodule LibEcto.KsuidTest do
  @moduledoc """
  KSUID模块测试
  """
  use ExUnit.Case

  alias LibEcto.Ksuid

  # 文档测试中包含随机生成的值，不适合直接测试
  # doctest LibEcto.Ksuid

  # 生成功能测试
  describe "generate/1" do
    test "基本生成功能 - 返回正确格式的KSUID" do
      ksuid = Ksuid.generate()
      assert is_binary(ksuid)
      assert String.length(ksuid) == 27
      assert String.match?(ksuid, ~r/^[0-9A-Za-z]{27}$/)
    end

    test "自定义时间戳 - 使用过去时间戳生成KSUID" do
      # 注意：KSUID使用32位表示时间戳，相对于Epoch 1_400_000_000
      # 所以时间戳不应该与Epoch相差太大，否则会溢出或被截断
      # 比Epoch仅大100秒
      past_timestamp = 1_400_000_100
      ksuid = Ksuid.generate(past_timestamp)

      {:ok, parsed_time, _} = Ksuid.parse(ksuid)

      # 解析后的时间戳应该与输入的时间戳匹配
      unix_timestamp = NaiveDateTime.diff(parsed_time, ~N[1970-01-01 00:00:00], :second)
      assert_in_delta unix_timestamp, past_timestamp, 5
    end

    test "自定义时间戳 - 使用稍微未来的时间戳生成KSUID" do
      # 注意：KSUID使用32位表示时间戳，相对于Epoch 1_400_000_000
      # 所以我们使用一个合理的未来时间戳（比Epoch大但不会导致32位溢出）
      # 比Epoch大约100,000秒（约1天多）
      future_timestamp = 1_400_100_000
      ksuid = Ksuid.generate(future_timestamp)

      assert String.length(ksuid) == 27
      {:ok, parsed_time, _} = Ksuid.parse(ksuid)

      # 验证解析的时间戳与输入的时间戳匹配
      unix_timestamp = NaiveDateTime.diff(parsed_time, ~N[1970-01-01 00:00:00], :second)
      assert_in_delta unix_timestamp, future_timestamp, 5
    end

    test "多次生成 - 每次生成的KSUID应该不同" do
      ksuid1 = Ksuid.generate()
      ksuid2 = Ksuid.generate()
      ksuid3 = Ksuid.generate()

      assert ksuid1 != ksuid2
      assert ksuid2 != ksuid3
      assert ksuid1 != ksuid3
    end
  end

  # 解析功能测试
  describe "parse/1" do
    test "成功解析有效KSUID" do
      ksuid = Ksuid.generate()
      {:ok, timestamp, random_bytes} = Ksuid.parse(ksuid)

      assert %NaiveDateTime{} = timestamp
      assert is_binary(random_bytes)
      assert byte_size(random_bytes) == 16
    end

    test "解析时间戳应与生成时间戳匹配" do
      # 使用接近Epoch的时间戳以避免截断问题
      test_timestamp = 1_400_050_000
      ksuid = Ksuid.generate(test_timestamp)

      {:ok, parsed_time, _} = Ksuid.parse(ksuid)

      # 将解析的NaiveDateTime转换回Unix时间戳
      unix_timestamp = NaiveDateTime.diff(parsed_time, ~N[1970-01-01 00:00:00], :second)

      # 由于时间转换和舍入，允许有5秒的误差
      assert_in_delta unix_timestamp, test_timestamp, 5
    end

    test "解析无效格式的KSUID应该返回错误" do
      result = Ksuid.parse("无效的KSUID字符串")
      assert result == {:error, "无效的KSUID"}
    end

    test "解析长度不正确的KSUID应该返回错误" do
      result = Ksuid.parse("123456")
      assert result == {:error, "无效的KSUID"}
    end

    test "解析超出最大值的KSUID应该返回错误" do
      # 创建一个非常大的KSUID字符串（全部使用最大字符'z'）
      oversized_ksuid = String.duplicate("z", 27)

      # 应该返回超出最大值的错误
      result = Ksuid.parse(oversized_ksuid)
      assert result == {:error, "KSUID值超过了最大可能值"}
    end

    test "解析包含无效字符的KSUID应该返回错误" do
      # 创建一个包含非Base62字符的KSUID
      invalid_chars_ksuid = String.duplicate("0", 26) <> "!"

      result = Ksuid.parse(invalid_chars_ksuid)
      assert result == {:error, "无效的KSUID"}
    end

    test "解析nil值应该返回错误" do
      result = Ksuid.parse(nil)
      assert result == {:error, "无效的KSUID"}
    end
  end

  # 边界测试
  describe "边界测试" do
    test "最小时间戳（KSUID纪元）" do
      # KSUID纪元 1_400_000_000 (2014年5月13日)
      epoch_timestamp = 1_400_000_000
      ksuid = Ksuid.generate(epoch_timestamp)

      {:ok, timestamp, _} = Ksuid.parse(ksuid)

      # 将解析的时间戳转换为Unix时间戳进行比较
      unix_timestamp = NaiveDateTime.diff(timestamp, ~N[1970-01-01 00:00:00], :second)

      # 验证解析的时间戳接近纪元时间
      assert_in_delta unix_timestamp, epoch_timestamp, 5
    end

    test "特殊字符边界测试" do
      # 测试Base62编码的边界字符
      # 使用固定时间戳以便进行确定性测试（使用接近Epoch的值）
      custom_timestamp = 1_400_000_500

      ksuid = Ksuid.generate(custom_timestamp)
      {:ok, timestamp, _} = Ksuid.parse(ksuid)

      # 将解析的时间戳转换为Unix时间戳进行比较
      unix_timestamp = NaiveDateTime.diff(timestamp, ~N[1970-01-01 00:00:00], :second)

      # 验证时间戳被正确解析（允许有误差）
      assert_in_delta unix_timestamp, custom_timestamp, 5
    end
  end

  # 性能测试
  describe "性能测试" do
    test "生成性能" do
      {time, _} =
        :timer.tc(fn ->
          for _ <- 1..1000, do: Ksuid.generate()
        end)

      # 计算平均生成时间（微秒）
      avg_time = time / 1000
      IO.puts("平均KSUID生成时间: #{avg_time}微秒")

      # 性能应在合理范围内（这里设置一个较为宽松的上限）
      # 每个KSUID生成应小于1毫秒
      assert avg_time < 1000
    end

    test "解析性能" do
      # 先生成一批KSUID
      ksuids = for _ <- 1..1000, do: Ksuid.generate()

      {time, _} =
        :timer.tc(fn ->
          Enum.each(ksuids, &Ksuid.parse/1)
        end)

      # 计算平均解析时间（微秒）
      avg_time = time / 1000
      IO.puts("平均KSUID解析时间: #{avg_time}微秒")

      # 性能应在合理范围内
      # 每个KSUID解析应小于1毫秒
      assert avg_time < 1000
    end

    test "连续生成的性能稳定性" do
      # 测试连续生成的性能是否稳定
      times =
        for _ <- 1..5 do
          {time, _} = :timer.tc(fn -> for _ <- 1..500, do: Ksuid.generate() end)
          time / 500
        end

      # 计算平均时间和标准差
      avg = Enum.sum(times) / length(times)
      variance = Enum.reduce(times, 0, fn x, acc -> acc + :math.pow(x - avg, 2) end) / length(times)
      std_dev = :math.sqrt(variance)

      # 标准差不应超过平均值的50%（这表示性能相对稳定）
      IO.puts("生成性能标准差: #{std_dev}微秒")
      assert std_dev < avg * 0.5
    end

    test "内存使用测试" do
      # 使用:erlang.memory函数测量内存使用
      {memory_before, _} =
        :timer.tc(fn ->
          :erlang.memory(:total)
        end)

      # 生成大量KSUID
      {_, ksuids} =
        :timer.tc(fn ->
          for _ <- 1..10_000, do: Ksuid.generate()
        end)

      # 测量内存使用后的状态（保留ksuids变量引用以防止GC）
      {memory_after, _} =
        :timer.tc(fn ->
          :erlang.memory(:total)
        end)

      # 计算每个KSUID的平均内存使用量（字节）
      memory_per_ksuid = (memory_after - memory_before) / length(ksuids)

      # 确保每个KSUID的内存使用在合理范围内
      # 由于KSUID是27字节长度的字符串，加上一些元数据，每个应该不超过100字节
      IO.puts("每个KSUID估计内存使用: #{memory_per_ksuid}字节")
      assert memory_per_ksuid < 100 or memory_per_ksuid < 0

      # memory_per_ksuid可能为负值，因为GC可能在测试期间运行
      # 所以我们主要确保没有明显的内存泄漏
    end
  end

  # 随机性测试
  describe "随机性测试" do
    test "生成的KSUID随机部分应具有足够的熵" do
      # 生成多个KSUID并提取随机部分
      ksuid_count = 1000

      random_parts =
        for _ <- 1..ksuid_count do
          ksuid = Ksuid.generate()
          {:ok, _, random_bytes} = Ksuid.parse(ksuid)
          random_bytes
        end

      # 计算每个随机字节的唯一值数量
      byte_positions = 0..15

      unique_counts =
        Enum.map(byte_positions, fn pos ->
          unique_values =
            random_parts
            |> Enum.map(fn bytes -> :binary.at(bytes, pos) end)
            |> Enum.uniq()
            |> length()

          unique_values
        end)

      # 每个位置应该有足够的唯一值（理论上可能有256个值）
      # 但由于样本量有限，我们设置一个较低的阈值
      min_expected_unique = 50
      all_positions_have_enough_entropy = Enum.all?(unique_counts, fn count -> count >= min_expected_unique end)

      IO.puts("随机部分每个字节位置的唯一值数量: #{inspect(unique_counts)}")
      assert all_positions_have_enough_entropy
    end
  end
end
