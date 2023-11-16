defmodule LibEcto.Ksuid do
  @moduledoc Path.join(__DIR__, "ksuid.md")
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias LibEcto.Base62

  @epoch 1_400_000_000
  @payload_length 16
  @ksuid_raw_length 20
  @ksuid_encoded_length 27
  @parse_error "the value given is more than the max Ksuid value possible"

  defp get_ts() do
    ts = System.system_time(:second) - @epoch
    # length of the time stamp is 32 bits
    <<ts::32>>
  end

  defp get_bytes() do
    :crypto.strong_rand_bytes(@payload_length)
  end

  @doc """
  This method returns a 20 byte Ksuid which has 4 bytes as timestamp
  and 16 bytes of crypto string bytes.

  ## Examples

      iex> Ksuid.generate()
      "0KZi94b2fnVzpGi60FoZgXIvUtYy"

  """
  @spec generate() :: binary()
  def generate() do
    kuid_as_bytes = get_ts() <> get_bytes()

    kuid_as_bytes
    |> Base62.encode()
    # <<48>> is zero on decoding
    |> apply_padding(<<48>>, @ksuid_encoded_length)
  end

  @spec parse(binary()) :: {:ok, NaiveDateTime.t(), binary()} | {:error, any()}
  def parse(ksuid) when is_binary(ksuid) and byte_size(ksuid) === @ksuid_encoded_length do
    decoded = Base62.decode!(ksuid)

    decoded
    |> byte_size()
    |> Kernel.>(@ksuid_raw_length)
    |> if do
      {:error, @parse_error}
    else
      decoded
      |> apply_padding(<<0>>, @ksuid_raw_length)
      |> normalize
    end
  end

  def parse(_), do: {:error, "invalid ksuid"}

  defp apply_padding(bytes, pad_char, expected_length) do
    pad = expected_length - byte_size(bytes)
    gen_padding(pad, pad_char) <> bytes
  end

  defp gen_padding(length, pad_char) when length > 0,
    do: pad_char <> gen_padding(length - 1, pad_char)

  defp gen_padding(0, _), do: <<>>

  defp normalize(<<ts::32, rand_bytes::binary-size(16)>>) do
    case DateTime.from_unix(ts + @epoch) do
      {:ok, time} -> {:ok, DateTime.to_naive(time), rand_bytes}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize(_), do: {:error, "invalid ksuid"}
end
