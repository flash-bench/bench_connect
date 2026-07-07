defmodule BenchConnect.HardwareTest do
  use ExUnit.Case, async: true

  alias BenchConnect.Hardware

  @allwinner Path.expand("../fixtures/allwinner", __DIR__)
  @rpi Path.expand("../fixtures/rpi", __DIR__)
  @host Path.expand("../fixtures/host", __DIR__)

  describe "detect/1" do
    test "detects hardware families from their filesystem signals" do
      assert Hardware.detect(@allwinner) == :allwinner
      assert Hardware.detect(@rpi) == :rpi
      assert Hardware.detect(@host) == :unknown
    end
  end

  describe "hw_serial/1" do
    test "dispatches to the detected hardware family" do
      assert Hardware.hw_serial(@allwinner) == "93407200:4c004814:01040a50:10681158"
      assert Hardware.hw_serial(@rpi) == "10000000abcdef01"
      assert Hardware.hw_serial(@host) == nil
    end
  end
end
