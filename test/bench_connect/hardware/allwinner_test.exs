defmodule BenchConnect.Hardware.AllwinnerTest do
  use ExUnit.Case, async: true

  alias BenchConnect.Hardware.Allwinner

  @allwinner Path.expand("../../fixtures/allwinner", __DIR__)
  @rpi Path.expand("../../fixtures/rpi", __DIR__)
  @host Path.expand("../../fixtures/host", __DIR__)

  describe "format_sid/1" do
    test "formats 16 SID bytes as sunxi-fel does" do
      bytes =
        <<0x00, 0x72, 0x40, 0x93, 0x14, 0x48, 0x00, 0x4C, 0x50, 0x0A, 0x04, 0x01, 0x58, 0x11,
          0x68, 0x10>>

      assert Allwinner.format_sid(bytes) == "93407200:4c004814:01040a50:10681158"
    end

    test "zero-pads small words" do
      assert Allwinner.format_sid(<<1::little-32, 0::little-32, 255::little-32, 16::little-32>>) ==
               "00000001:00000000:000000ff:00000010"
    end
  end

  describe "hw_serial/1" do
    test "reads and formats the SID from nvmem" do
      assert Allwinner.hw_serial(@allwinner) == "93407200:4c004814:01040a50:10681158"
    end

    test "nil when the nvmem file is absent" do
      assert Allwinner.hw_serial(@host) == nil
    end
  end

  describe "present?/1" do
    test "true on an Allwinner fixture tree" do
      assert Allwinner.present?(@allwinner)
    end

    test "false on RPi and host trees" do
      refute Allwinner.present?(@rpi)
      refute Allwinner.present?(@host)
    end
  end
end
