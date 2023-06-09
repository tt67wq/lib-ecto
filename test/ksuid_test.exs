defmodule LibEcto.KsuidTest do
  use ExUnit.Case

  alias LibEcto.Ksuid

  test "generate/0 generates a ksuid" do
    assert is_binary(Ksuid.generate())
  end

  test "generate/0 generates different ksuid on each call" do
    assert Ksuid.generate() != Ksuid.generate()
  end

  test "parse/1 parses ksuid into timestamp and key" do
    ksuid = Ksuid.generate()
    assert {:ok, _, _} = Ksuid.parse(ksuid)
  end

  test "parse/1 returns error if invalid ksuid" do
    assert {:error, "invalid ksuid"} = Ksuid.parse("invalid-ksuid")
  end

  test "ksuid parsed has same timestamp as generated" do
    ksuid = Ksuid.generate()
    {:ok, timestamp, _} = Ksuid.parse(ksuid)

    assert timestamp == NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  end

  test "different ksuid have different timestamps" do
    {:ok, t1, _} = Ksuid.parse(Ksuid.generate())
    Process.sleep(1000)
    {:ok, t2, _} = Ksuid.parse(Ksuid.generate())

    assert t1 != t2
  end
end
