defmodule BenchConnect.Hardware.RPi do
  @moduledoc """
  Raspberry Pi hardware detection and board serial.

  The board serial is the value the bootloader substitutes for `{serial}`
  during network boot (PXE), which is what a Flash Bench captured as the CM's
  job serial. Advertised as `hw_serial` so the bench can correlate a rebooted
  CM whose primary `serial` is now a provisioned HSM/NervesKey serial.
  """

  @model "proc/device-tree/model"
  @compatible "proc/device-tree/compatible"
  @serial_number "proc/device-tree/serial-number"
  @cpuinfo "proc/cpuinfo"

  @doc "Whether this looks like a Raspberry Pi."
  @spec present?(Path.t()) :: boolean()
  def present?(root) do
    raspberry_pi_file?(root, @model) or raspberry_pi_file?(root, @compatible) or
      hw_serial(root) != nil
  end

  @doc "The Raspberry Pi board serial, or nil if unreadable."
  @spec hw_serial(Path.t()) :: String.t() | nil
  def hw_serial(root) do
    device_tree_serial(root) || cpuinfo_serial(root)
  end

  # Canonical source: the VideoCore-provided board serial (null-terminated ASCII).
  defp device_tree_serial(root) do
    case File.read(Path.join(root, @serial_number)) do
      {:ok, bin} -> bin |> String.trim_trailing(<<0>>) |> presence()
      _ -> nil
    end
  end

  defp cpuinfo_serial(root) do
    with {:ok, contents} <- File.read(Path.join(root, @cpuinfo)),
         [_, serial] <- Regex.run(~r/^Serial\s*:\s*([0-9a-fA-F]+)/m, contents) do
      presence(serial)
    else
      _ -> nil
    end
  end

  defp raspberry_pi_file?(root, path) do
    case File.read(Path.join(root, path)) do
      {:ok, contents} -> String.contains?(String.downcase(contents), "raspberry")
      _ -> false
    end
  end

  defp presence(s) do
    case s |> String.trim() |> String.downcase() do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
