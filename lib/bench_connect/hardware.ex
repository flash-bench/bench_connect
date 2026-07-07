defmodule BenchConnect.Hardware do
  @moduledoc """
  Detects the hardware family the code is running on and derives its
  immutable hardware serial (`hw_serial`).

  Detection is purely filesystem-based (device tree / sysfs), so it works the
  same on any Nerves system and degrades to `:unknown` on the host or on
  unrecognized hardware. All reads are rooted at the configurable `:fs_root`
  (default `"/"`) so tests can point at fixture trees.
  """

  alias BenchConnect.Hardware.Allwinner
  alias BenchConnect.Hardware.RPi

  @type kind :: :allwinner | :rpi | :unknown

  @doc "The hardware family this code is running on."
  @spec detect(Path.t()) :: kind()
  def detect(root \\ fs_root()) do
    cond do
      Allwinner.present?(root) -> :allwinner
      RPi.present?(root) -> :rpi
      true -> :unknown
    end
  end

  @doc """
  The hardware serial for the detected hardware family, or nil when the
  hardware is unrecognized or the serial cannot be read.
  """
  @spec hw_serial(Path.t()) :: String.t() | nil
  def hw_serial(root \\ fs_root()) do
    case detect(root) do
      :allwinner -> Allwinner.hw_serial(root)
      :rpi -> RPi.hw_serial(root)
      :unknown -> nil
    end
  end

  @doc false
  @spec fs_root() :: Path.t()
  def fs_root, do: Application.get_env(:bench_connect, :fs_root, "/")
end
