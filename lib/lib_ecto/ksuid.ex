defmodule LibEcto.Ksuid do
  @moduledoc """
  KSUID (K-Sortable Unique Identifier) 生成和解析模块

  KSUID 是一种可排序的唯一标识符，由时间戳和随机数据组成。
  结构：4字节时间戳 + 16字节随机数据，Base62编码后27字符。

  ## 特点

  * 时间排序：基于时间戳的排序能力
  * 高唯一性：使用随机数据确保唯一性
  * URL安全：使用Base62编码，可在URL中安全使用
  * 高效存储：二进制表示高效紧凑

  ## 使用示例

      # 生成KSUID
      ksuid = LibEcto.Ksuid.generate()

      # 使用自定义时间戳生成KSUID
      timestamp = System.system_time(:second)
      ksuid = LibEcto.Ksuid.generate(timestamp)

      # 解析KSUID
      {:ok, timestamp, random_bytes} = LibEcto.Ksuid.parse(ksuid)
  """

  alias LibEcto.Base62

  @typedoc """
  KSUID 字符串表示形式，Base62编码，27字符长度
  """
  @type t :: binary()

  @typedoc """
  表示自Unix纪元以来的秒数的非负整数
  """
  @type timestamp :: non_neg_integer()

  @typedoc """
  解析结果，成功返回时间戳和随机数据，失败返回错误信息
  """
  @type parse_result :: {:ok, NaiveDateTime.t(), binary()} | {:error, binary()}

  # KSUID相关常量
  # KSUID纪元时间（2014年5月13日）
  @epoch 1_400_000_000
  # 随机数据长度（字节）
  @payload_length 16
  # 原始KSUID长度（4字节时间戳 + 16字节随机数据）
  @ksuid_raw_length 20
  # Base62编码后的KSUID长度
  @ksuid_encoded_length 27

  # 错误消息
  @error_max_value "KSUID值超过了最大可能值"
  @error_invalid_ksuid "无效的KSUID"

  @doc """
  生成一个新的KSUID。

  可选参数允许提供自定义时间戳，默认使用当前系统时间。

  ## 参数

  * `ts` - 可选的时间戳（Unix秒数）。默认为当前系统时间。

  ## 返回值

  返回生成的KSUID字符串，Base62编码，27字符长度。

  ## 示例

      iex> ksuid = LibEcto.Ksuid.generate()
      iex> is_binary(ksuid) and String.length(ksuid) == 27
      true

      iex> ksuid = LibEcto.Ksuid.generate(1632304869)
      iex> is_binary(ksuid) and String.length(ksuid) == 27
      true
  """
  @spec generate(timestamp()) :: t()
  def generate(ts \\ System.system_time(:second)) do
    # 生成时间戳字节
    timestamp_bytes = get_ts(ts)
    # 生成随机字节
    random_bytes = get_bytes()
    # 组合原始KSUID数据
    raw_ksuid = timestamp_bytes <> random_bytes
    # Base62编码
    encoded = Base62.encode(raw_ksuid)
    # 应用填充确保长度正确（使用字符"0"填充）
    apply_padding(encoded, @ksuid_encoded_length)
  end

  @doc """
  解析KSUID字符串，提取时间戳和随机数据部分。

  ## 参数

  * `ksuid` - 要解析的KSUID字符串

  ## 返回值

  成功时返回 `{:ok, timestamp, random_bytes}`，其中：
  * `timestamp` - NaiveDateTime格式的时间戳
  * `random_bytes` - 16字节的随机数据

  失败时返回 `{:error, reason}`

  ## 示例

      iex> ksuid = LibEcto.Ksuid.generate()
      iex> {:ok, timestamp, random_bytes} = LibEcto.Ksuid.parse(ksuid)
      iex> is_struct(timestamp, NaiveDateTime) and byte_size(random_bytes) == 16
      true
  """
  @spec parse(binary()) :: parse_result()
  def parse(ksuid) when is_binary(ksuid) and byte_size(ksuid) === @ksuid_encoded_length do
    # 尝试解码KSUID
    with {:ok, decoded} <- decode_ksuid(ksuid) do
      extract_components(decoded)
    end
  end

  def parse(_), do: {:error, @error_invalid_ksuid}

  # 解码KSUID并验证长度
  defp decode_ksuid(ksuid) do
    decoded = Base62.decode!(ksuid)

    if byte_size(decoded) > @ksuid_raw_length do
      {:error, @error_max_value}
    else
      {:ok, pad_bytes(decoded, @ksuid_raw_length)}
    end
  rescue
    _ -> {:error, @error_invalid_ksuid}
  end

  # 从解码后的KSUID中提取组件
  defp extract_components(decoded) do
    case normalize(decoded) do
      {:ok, timestamp, random_bytes} -> {:ok, timestamp, random_bytes}
      {:error, reason} -> {:error, reason}
    end
  end

  # 内部函数

  # 生成4字节的时间戳（相对于KSUID纪元）
  defp get_ts(ts), do: <<ts - @epoch::32>>

  # 生成16字节的随机数据
  defp get_bytes, do: :crypto.strong_rand_bytes(@payload_length)

  # 为字符串数据填充到指定长度，默认使用"0"填充
  defp apply_padding(string, expected_length) do
    pad = expected_length - byte_size(string)

    if pad > 0 do
      String.duplicate("0", pad) <> string
    else
      string
    end
  end

  # 为二进制数据填充到指定长度，使用<<0>>填充
  defp pad_bytes(bytes, expected_length) do
    pad = expected_length - byte_size(bytes)

    if pad > 0 do
      padding = for _ <- 1..pad, into: <<>>, do: <<0>>
      padding <> bytes
    else
      bytes
    end
  end

  # 解析和格式化KSUID的二进制表示
  defp normalize(<<ts::32, rand_bytes::binary-size(16)>>) do
    case DateTime.from_unix(ts + @epoch) do
      {:ok, time} -> {:ok, DateTime.to_naive(time), rand_bytes}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize(_), do: {:error, @error_invalid_ksuid}
end
