# BenchConnect

Makes a Nerves device discoverable by a [Flash Bench](https://github.com/flash-bench/bench).

Add the dependency and the device automatically advertises the
`_flash-bench-device._tcp` mDNS service on boot — no configuration required.
The bench uses it to find devices on the network and, critically, to
correlate a freshly flashed board back to the flashing job that produced it,
even after provisioning changes the device's primary serial number.

## Installation

```elixir
def deps do
  [
    {:bench_connect, github: "flash-bench/bench_connect"}
  ]
end
```

That's it. `bench_connect` pulls in `mdns_lite` and `nerves_runtime` and
publishes the service when the application starts.

## What is advertised

A `_flash-bench-device._tcp` service with port `0` (there is nothing to
connect to — the service exists to carry identity) and these TXT records:

| Key            | Source                                                | Notes                              |
| -------------- | ----------------------------------------------------- | ---------------------------------- |
| `serial`       | `Nerves.Runtime.serial_number/0`                       | Always present                     |
| `hw_serial`    | Hardware-specific (see below)                          | Present when derivable             |
| `version`      | `Nerves.Runtime.KV.get_active("nerves_fw_version")`    | Omitted when blank                 |
| `product`      | `... "nerves_fw_product"`                              | Omitted when blank                 |
| `description`  | `... "nerves_fw_description"`                          | Omitted when blank                 |
| `platform`     | `... "nerves_fw_platform"`                             | Omitted when blank                 |
| `architecture` | `... "nerves_fw_architecture"`                         | Omitted when blank                 |
| `author`       | `... "nerves_fw_author"`                               | Omitted when blank                 |
| `uuid`         | `... "nerves_fw_uuid"`                                 | Omitted when blank                 |

These mirror the standard [`_nerves-device._tcp`](https://github.com/nerves-networking/nerves_discovery)
keys, plus `hw_serial`. BenchConnect deliberately does **not** publish
`_nerves-device._tcp` itself; add the recipe from the `nerves_discovery`
README if you also want the standard service.

## `hw_serial` — hardware auto-detection

`serial` can change over a device's life (e.g. once a NervesKey/HSM is
provisioned, `Nerves.Runtime.serial_number/0` returns the manufacturer
serial). `hw_serial` is the immutable identity burned into the SoC, which is
what the bench saw when it flashed the bare board. BenchConnect detects the
hardware it is running on and derives it accordingly:

- **Allwinner** (e.g. Trellis / T113): the 128-bit chip SID read from
  `/sys/bus/nvmem/devices/sunxi-sid0/nvmem`, formatted exactly as `sunxi-fel`
  prints it — four little-endian 32-bit words as lowercase hex, colon-joined:
  `93407200:4c004814:01040a50:10681158`.
- **Raspberry Pi**: the board serial from `/proc/device-tree/serial-number`
  (the value the bootloader substitutes for `{serial}` during network boot),
  falling back to the `Serial` line of `/proc/cpuinfo`. Lowercased.
- **Unknown hardware / host**: `hw_serial` is omitted.

## Configuration (all optional)

```elixir
config :bench_connect,
  # Disable the advertisement entirely.
  enabled: false,
  # Extra TXT records, as {"key", "value"} tuples or "key=value" strings.
  extra_txt: [{"site", "line-2"}]
```

If the device's identity changes at runtime (e.g. after HSM provisioning),
call `BenchConnect.republish/0` to re-derive and replace the advertisement.

## Verifying

From macOS:

```sh
dns-sd -B _flash-bench-device._tcp            # browse for instances
dns-sd -L "<instance>" _flash-bench-device._tcp   # resolve one; shows the TXT records
```

From Linux:

```sh
avahi-browse -r _flash-bench-device._tcp
```
