defmodule BenchConnect.Info do
  @moduledoc """
  Builds the TXT records advertised by the `_flash-bench-device._tcp` service.

  The keys mirror the standard `_nerves-device._tcp` service (`serial` plus
  the `nerves_fw_*` firmware metadata) with one addition: `hw_serial`, the
  immutable hardware identity from `BenchConnect.Hardware`. Keys whose values
  cannot be derived are omitted rather than advertised empty.
  """

  alias BenchConnect.Hardware

  @kv_keys ~w(version product description platform architecture author uuid)

  @doc "The TXT records as a list of `\"key=value\"` strings."
  @spec txt_payload() :: [String.t()]
  def txt_payload do
    identity_pairs() ++ extra_txt()
  end

  defp identity_pairs do
    [
      {"serial", presence(serial_number())},
      {"hw_serial", Hardware.hw_serial()}
      | Enum.map(@kv_keys, fn key ->
          {key, presence(Nerves.Runtime.KV.get_active("nerves_fw_" <> key))}
        end)
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Enum.map(fn {key, value} -> "#{key}=#{value}" end)
  end

  # Extra TXT records from `config :bench_connect, extra_txt: [...]` — either
  # {"key", "value"} tuples or preformatted "key=value" strings.
  defp extra_txt do
    :bench_connect
    |> Application.get_env(:extra_txt, [])
    |> Enum.map(fn
      {key, value} -> "#{key}=#{value}"
      entry when is_binary(entry) -> entry
    end)
  end

  # `Nerves.Runtime.serial_number/0` already rescues to "unconfigured", but
  # guard anyway — the publisher must never crash over identity derivation.
  defp serial_number do
    Nerves.Runtime.serial_number()
  rescue
    _ -> "unconfigured"
  end

  defp presence(nil), do: nil

  defp presence(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end
end
