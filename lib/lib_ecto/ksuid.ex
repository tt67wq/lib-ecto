defmodule LibEcto.Ksuid do
  @moduledoc "docs/ksuid.md"
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

    cond do
      byte_size(decoded) > @ksuid_raw_length ->
        {:error, @parse_error}

      # for any other case we are adding padding to make the string of 20 length.
      true ->
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

defmodule LibEcto.KsuidType do
  @moduledoc """
  types for ksuid
  uses string/varchar as storage type.

  ## Example
  ```Elixir
  defmodule TestSchema do
    use Ecto.Schema
    alias LibEcto.KsuidType

    @primary_key {:id, KsuidType, autogenerate: true}
    schema "test" do
      field :name, :string
      field :inserted_at, :utc_datetime, virtual: true
    end

    def inserted_at(%TestSchema{id: ksuid} = row) do
       {:ok, time_stamp, _} = LibEcto.Ksuid.parse(ksuid)
       %TestSchema{row | inserted_at: time_stamp}
    end
  end
  ```
  """

  use Ecto.Type
  alias LibEcto.Ksuid

  def type, do: :string

  def cast(ksuid) when is_binary(ksuid), do: {:ok, ksuid}
  def cast(_), do: :error

  @doc """
  Same as `cast/1` but raises `Ecto.CastError` on invalid arguments.
  """
  def cast!(value) do
    case cast(value) do
      {:ok, ksuid} -> ksuid
      :error -> raise Ecto.CastError, type: __MODULE__, value: value
    end
  end

  def load(ksuid), do: {:ok, ksuid}

  def dump(binary) when is_binary(binary), do: {:ok, binary}
  def dump(_), do: :error

  # Callback invoked by autogenerate fields - this is all that really matters
  # just passing around the binary otherwise.
  @doc false
  def autogenerate, do: Ksuid.generate()
end
