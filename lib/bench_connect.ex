defmodule BenchConnect do
  @moduledoc """
  Makes a Nerves device discoverable by a Flash Bench.

  Add `:bench_connect` as a dependency and the device automatically advertises
  the `_flash-bench-device._tcp` mDNS service on boot. The service's TXT
  records carry the device's identity — at minimum its `serial` and (when the
  hardware provides one) its `hw_serial` — plus the same firmware metadata
  keys advertised by the standard `_nerves-device._tcp` service.

  The `hw_serial` is the immutable hardware identity the bench uses to
  correlate a rebooted board back to the flashing job that produced it. It is
  auto-detected per hardware family (see `BenchConnect.Hardware`):

    * Allwinner (e.g. Trellis) — the chip SID read from nvmem, formatted
      exactly as `sunxi-fel` prints it (`93407200:4c004814:...`).
    * Raspberry Pi — the SoC serial from the device tree (falling back to
      `/proc/cpuinfo`).

  This library deliberately does **not** publish `_nerves-device._tcp`; see
  the `nerves_discovery` README if you also want the standard service.
  """

  @service_id :flash_bench_device
  @protocol "flash-bench-device"

  @doc "The `MdnsLite` service id used for the advertisement."
  @spec service_id() :: atom()
  def service_id, do: @service_id

  @doc "The mDNS service type advertised, e.g. for browsing with `dns-sd -B`."
  @spec service_type() :: String.t()
  def service_type, do: "_#{@protocol}._tcp"

  @doc "The application protocol portion of the service type."
  @spec protocol() :: String.t()
  def protocol, do: @protocol

  @doc "The TXT records that would be advertised right now."
  @spec txt_payload() :: [String.t()]
  defdelegate txt_payload, to: BenchConnect.Info

  @doc """
  Re-derive the TXT records and replace the advertisement.

  Useful when the device's identity changes at runtime — e.g. after a
  NervesKey/HSM is provisioned and `Nerves.Runtime.serial_number/0` starts
  returning the manufacturer serial.
  """
  @spec republish() :: :ok
  defdelegate republish, to: BenchConnect.Publisher
end
