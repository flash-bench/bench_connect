defmodule BenchConnect.InfoTest do
  use ExUnit.Case

  alias BenchConnect.Info

  # Test config seeds the InMemory KV (see config/config.exs) and points
  # :fs_root at the empty host fixture, so hw_serial is underivable here.

  test "advertises the serial and the seeded firmware metadata" do
    payload = Info.txt_payload()

    # On the host boardid is unavailable, so nerves_runtime reports the
    # placeholder serial — advertised as-is, mirroring _nerves-device._tcp.
    assert "serial=unconfigured" in payload
    assert "version=1.2.3" in payload
    assert "product=widget" in payload
    assert "platform=trellis" in payload
    assert "architecture=arm" in payload
    assert "uuid=0540f0cd-f95a-5596-d152-221a70c078a9" in payload
  end

  test "omits keys whose values are missing or blank" do
    payload = Info.txt_payload()

    # description is seeded blank, author isn't seeded, and the host fixture
    # tree has no hardware serial.
    refute Enum.any?(payload, &String.starts_with?(&1, "description="))
    refute Enum.any?(payload, &String.starts_with?(&1, "author="))
    refute Enum.any?(payload, &String.starts_with?(&1, "hw_serial="))
  end

  test "includes the hardware serial when the hardware provides one" do
    Application.put_env(:bench_connect, :fs_root, Path.expand("../fixtures/allwinner", __DIR__))
    on_exit(fn -> Application.put_env(:bench_connect, :fs_root, "test/fixtures/host") end)

    assert "hw_serial=93407200:4c004814:01040a50:10681158" in Info.txt_payload()
  end

  test "appends configured extra TXT records in either form" do
    Application.put_env(:bench_connect, :extra_txt, [{"site", "line-2"}, "rack=b4"])
    on_exit(fn -> Application.delete_env(:bench_connect, :extra_txt) end)

    payload = Info.txt_payload()
    assert "site=line-2" in payload
    assert "rack=b4" in payload
  end
end
