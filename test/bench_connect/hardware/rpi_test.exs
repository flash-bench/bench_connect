defmodule BenchConnect.Hardware.RPiTest do
  use ExUnit.Case, async: true

  alias BenchConnect.Hardware.RPi

  @rpi Path.expand("../../fixtures/rpi", __DIR__)
  @cpuinfo_only Path.expand("../../fixtures/rpi_cpuinfo_only", __DIR__)
  @allwinner Path.expand("../../fixtures/allwinner", __DIR__)
  @host Path.expand("../../fixtures/host", __DIR__)

  describe "hw_serial/1" do
    test "prefers the device-tree serial, trimming the trailing NUL and lowercasing" do
      # Fixture file contains "10000000ABCDEF01\0"
      assert RPi.hw_serial(@rpi) == "10000000abcdef01"
    end

    test "falls back to /proc/cpuinfo when the device tree has no serial" do
      assert RPi.hw_serial(@cpuinfo_only) == "10000000cafef00d"
    end

    test "nil when no serial source is readable" do
      assert RPi.hw_serial(@host) == nil
    end
  end

  describe "present?/1" do
    test "true on RPi fixture trees" do
      assert RPi.present?(@rpi)
      assert RPi.present?(@cpuinfo_only)
    end

    test "false on Allwinner and host trees" do
      refute RPi.present?(@allwinner)
      refute RPi.present?(@host)
    end
  end
end
