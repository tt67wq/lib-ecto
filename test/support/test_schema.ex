defmodule LibEctoV2.Test.Schema do
  @moduledoc """
  测试用的 Schema 模块，用于 LibEctoV2 测试。
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :string, []}
  schema "test_schema" do
    field(:name, :string)
    field(:value, :string)

    timestamps()
  end

  @doc """
  标准的 changeset 函数，用于验证和准备数据。
  """
  def changeset(schema, params) do
    schema
    |> cast(params, [:name, :value])
    |> validate_required([:name, :value])
  end

  @doc """
  构建一个测试实例。
  """
  def build(id, name, value) do
    %__MODULE__{
      id: id,
      name: name,
      value: value
    }
  end
end
