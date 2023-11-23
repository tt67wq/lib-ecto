defmodule Base62Test do
  @moduledoc false
  use ExUnit.Case

  alias LibEcto.Base62

  describe "Base62" do
    test "encodes and decodes binary data" do
      binary_data = "hello world"
      encoded_data = Base62.encode(binary_data)
      decoded_data = Base62.decode!(encoded_data)

      assert decoded_data == binary_data
    end

    test "encodes and decodes integers" do
      integer_data = 1_234_567_890
      encoded_data = Base62.encode(integer_data)
      <<decoded_data::32>> = Base62.decode!(encoded_data)

      assert decoded_data == integer_data
    end

    test "encodes and decodes 0" do
      integer_data = 0
      encoded_data = Base62.encode(integer_data)
      decoded_data = Base62.decode!(encoded_data)

      assert decoded_data == <<>>
    end

    test "encodes and decodes empty binary data" do
      binary_data = ""
      encoded_data = Base62.encode(binary_data)
      decoded_data = Base62.decode!(encoded_data)

      assert decoded_data == binary_data
    end

    test "encodes and decodes binary data with special characters" do
      binary_data =
        <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
          25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46,
          47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68,
          69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90,
          91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109,
          110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126,
          127>>

      encoded_data = Base62.encode(binary_data)
      decoded_data = Base62.decode!(encoded_data)

      assert decoded_data == binary_data
    end

    # test "raises an error when decoding invalid data" do
    #   invalid_data = "invalid data"

    #   assert_raise ArgumentError, message: "invalid Base62 data" do
    #     Base62.decode!(invalid_data)
    #   end
    # end
  end
end
