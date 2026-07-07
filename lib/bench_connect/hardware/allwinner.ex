defmodule BenchConnect.Hardware.Allwinner do
  @moduledoc """
  Allwinner (sunxi) hardware detection and SID-derived hardware serial.

  The 128-bit chip SID is exposed by the kernel's sunxi-sid nvmem driver. It
  is formatted exactly as `sunxi-fel` prints it — four little-endian 32-bit
  words as zero-padded lowercase hex, colon-joined (e.g.
  `93407200:4c004814:01040a50:10681158`) — so a Flash Bench can match the
  running board back to the SID it saw in FEL mode.
  """

  @nvmem "sys/bus/nvmem/devices/sunxi-sid0/nvmem"
  @compatible "proc/device-tree/compatible"

  @doc "Whether this looks like an Allwinner board."
  @spec present?(Path.t()) :: boolean()
  def present?(root) do
    File.exists?(Path.join(root, @nvmem)) or compatible_allwinner?(root)
  end

  @doc "The SID-derived hardware serial, or nil when the SID cannot be read."
  @spec hw_serial(Path.t()) :: String.t() | nil
  def hw_serial(root) do
    case File.read(Path.join(root, @nvmem)) do
      {:ok, <<sid::binary-size(16), _::binary>>} -> format_sid(sid)
      _ -> nil
    end
  end

  @doc """
  Formats 16 SID bytes the way `sunxi-fel` prints them: four little-endian
  u32 words as `%08x`, colon-joined.
  """
  @spec format_sid(<<_::128>>) :: String.t()
  def format_sid(<<w0::little-32, w1::little-32, w2::little-32, w3::little-32>>) do
    Enum.map_join([w0, w1, w2, w3], ":", fn word ->
      word
      |> Integer.to_string(16)
      |> String.downcase()
      |> String.pad_leading(8, "0")
    end)
  end

  # The device-tree compatible list (null-separated strings) names the SoC
  # family, e.g. "protolux,trellis-t113\0allwinner,sun8i-t113s\0".
  defp compatible_allwinner?(root) do
    case File.read(Path.join(root, @compatible)) do
      {:ok, contents} -> String.contains?(String.downcase(contents), "allwinner")
      _ -> false
    end
  end
end
