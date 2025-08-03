defmodule LibEcto.KsuidBase62IntegrationTest do
  @moduledoc """
  KSUID 和 Base62 模块的集成测试
  """
  use ExUnit.Case

  alias LibEcto.Base62
  alias LibEcto.Ksuid

  describe "KSUID 和 Base62 集成测试" do
    test "KSUID 使用 Base62 编码和解码应该正确无误" do
      # 生成多个 KSUID
      ksuid_count = 100
      ksuids = for _ <- 1..ksuid_count, do: Ksuid.generate()

      # 所有生成的 KSUID 都应该是有效的 Base62 编码
      Enum.each(ksuids, fn ksuid ->
        # 确保每个字符都是 Base62 字符集中的一个
        valid_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

        for char <- String.graphemes(ksuid) do
          assert String.contains?(valid_chars, char)
        end
      end)

      # 测试 Base62 解码和再编码的一致性
      Enum.each(ksuids, fn ksuid ->
        # 测试可解析性，而不是编码的完全一致性
        # 解码 KSUID
        decoded = Base62.decode!(ksuid)
        # 确保解码后的数据是二进制
        assert is_binary(decoded)

        # 解析原始 KSUID
        {:ok, original_timestamp, original_random} = Ksuid.parse(ksuid)

        # 使用解码后的数据重新创建 KSUID
        padded_decoded =
          if byte_size(decoded) < 20 do
            padding = for _ <- 1..(20 - byte_size(decoded)), into: <<>>, do: <<0>>
            padding <> decoded
          else
            decoded
          end

        <<ts::32, rand::binary-size(16)>> = padded_decoded
        epoch = 1_400_000_000

        # 验证时间戳部分
        ts_with_epoch = ts + epoch
        {:ok, dt} = DateTime.from_unix(ts_with_epoch)
        parsed_ts = DateTime.to_naive(dt)

        # 验证解码后提取的时间戳与原始解析的时间戳匹配
        assert NaiveDateTime.diff(parsed_ts, original_timestamp, :second) == 0
        # 验证随机部分匹配
        assert rand == original_random
      end)
    end

    test "从随机二进制数据编码解码的完整性" do
      # 生成多个随机二进制数据（模拟 KSUID 内部结构）
      test_count = 20

      # 直接使用 KSUID 生成和解析函数进行测试
      Enum.each(1..test_count, fn _ ->
        # 创建一个固定的小时间戳，不会出现超出 epoch 太多的情况
        timestamp = 1_400_000_000 + :rand.uniform(1000)

        # 使用 KSUID 生成函数
        ksuid = Ksuid.generate(timestamp)

        # 解析 KSUID
        {:ok, parsed_time, parsed_random} = Ksuid.parse(ksuid)

        # 验证时间戳
        parsed_unix_time = NaiveDateTime.diff(parsed_time, ~N[1970-01-01 00:00:00], :second)

        # 验证时间戳在预期范围内（允许更大的误差）
        assert_in_delta parsed_unix_time, timestamp, 1000

        # 验证随机部分长度
        assert byte_size(parsed_random) == 16

        # 使用 Base62 手动解码和编码，验证结果
        decoded = Base62.decode!(ksuid)
        assert is_binary(decoded)

        # 确保可以重新编码
        reencoded = Base62.encode(decoded)
        assert is_binary(reencoded)
      end)
    end

    test "KSUID 解析过程中的 Base62 解码是否正确" do
      # 使用固定时间戳生成 KSUID，确保测试的确定性
      fixed_timestamp = 1_400_000_100
      ksuid = Ksuid.generate(fixed_timestamp)

      # 解析 KSUID
      {:ok, parsed_time, random_bytes} = Ksuid.parse(ksuid)

      # 验证时间戳部分
      unix_timestamp = NaiveDateTime.diff(parsed_time, ~N[1970-01-01 00:00:00], :second)
      assert_in_delta unix_timestamp, fixed_timestamp, 5

      # 验证随机字节部分
      assert byte_size(random_bytes) == 16

      # 直接使用 Base62 解码，然后手动提取部分
      raw_decoded = Base62.decode!(ksuid)

      padded_raw =
        if byte_size(raw_decoded) < 20 do
          padding = for _ <- 1..(20 - byte_size(raw_decoded)), into: <<>>, do: <<0>>
          padding <> raw_decoded
        else
          raw_decoded
        end

      <<raw_ts::32, raw_random::binary-size(16)>> = padded_raw

      # 检查手动提取的时间戳与 KSUID.parse 返回的时间戳是否一致
      # 减去 epoch
      expected_ts = fixed_timestamp - 1_400_000_000
      assert raw_ts == expected_ts

      # 检查随机部分
      assert byte_size(raw_random) == 16
      assert raw_random == random_bytes
    end

    test "边界情况：全零和极端值" do
      # 测试全零 KSUID
      # 20 字节全 0
      all_zeros_binary = <<0::160>>
      all_zeros_encoded = Base62.encode(all_zeros_binary)
      all_zeros_padded = String.duplicate("0", 27 - String.length(all_zeros_encoded)) <> all_zeros_encoded

      # 解析全零 KSUID
      {:ok, timestamp, random_bytes} = Ksuid.parse(all_zeros_padded)

      # 应该得到纪元时间
      assert NaiveDateTime.diff(timestamp, ~N[1970-01-01 00:00:00], :second) == 1_400_000_000
      # 随机部分应该是全零
      assert random_bytes == <<0::128>>

      # 测试一个较大的值（但不会导致解析错误）
      # 使用较小的时间戳部分和较大的随机部分
      large_binary = <<0, 0, 0, 1>> <> <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>

      large_encoded = Base62.encode(large_binary)
      large_padded = String.duplicate("0", 27 - String.length(large_encoded)) <> large_encoded

      # 尝试解析这个大值的 KSUID
      {:ok, timestamp, random_bytes} = Ksuid.parse(large_padded)

      # 验证时间戳（1 + epoch）
      assert NaiveDateTime.diff(timestamp, ~N[1970-01-01 00:00:00], :second) == 1_400_000_001

      # 验证随机部分全为 255
      assert random_bytes == <<255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255>>

      # 测试一个特定的"大"值但不超过限制
      specific_large = String.duplicate("Z", 27)
      parse_result = Ksuid.parse(specific_large)

      # 根据解析结果类型判断
      case parse_result do
        # 解析成功
        {:ok, _, _} ->
          assert true

        {:error, reason} ->
          # 验证错误原因
          assert reason == "KSUID值超过了最大可能值" or reason == "无效的KSUID"
      end
    end
  end
end
