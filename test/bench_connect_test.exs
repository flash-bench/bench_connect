defmodule BenchConnectTest do
  use ExUnit.Case, async: true

  test "service identity" do
    assert BenchConnect.service_id() == :flash_bench_device
    assert BenchConnect.protocol() == "flash-bench-device"
    assert BenchConnect.service_type() == "_flash-bench-device._tcp"
  end
end
