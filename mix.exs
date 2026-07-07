defmodule BenchConnect.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/flash-bench/bench_connect"

  def project do
    [
      app: :bench_connect,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {BenchConnect.Application, []}
    ]
  end

  defp description do
    """
    Makes a Nerves device discoverable by a Flash Bench. Add the dependency and
    the device automatically advertises the `_flash-bench-device._tcp` mDNS
    service with its serial, hardware serial, and firmware metadata.
    """
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:mdns_lite, "~> 0.9"},
      {:nerves_runtime, "~> 0.13"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
