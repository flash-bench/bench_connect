import Config

# This config only applies when bench_connect is the root project (dev/test).
# Host projects configure :bench_connect in their own config.

if config_env() == :test do
  # Don't auto-start the publisher in tests; they drive the modules directly.
  config :bench_connect,
    enabled: false,
    fs_root: "test/fixtures/host"

  # Seed the in-memory KV store the way a Nerves device's U-Boot environment
  # would be populated, so Info tests have firmware metadata to read.
  config :nerves_runtime,
    kv_backend:
      {Nerves.Runtime.KVBackend.InMemory,
       contents: %{
         "nerves_fw_active" => "a",
         "a.nerves_fw_architecture" => "arm",
         "a.nerves_fw_platform" => "trellis",
         "a.nerves_fw_product" => "widget",
         "a.nerves_fw_version" => "1.2.3",
         "a.nerves_fw_uuid" => "0540f0cd-f95a-5596-d152-221a70c078a9",
         # Left blank to prove empty values are omitted from TXT.
         "a.nerves_fw_description" => ""
       }}
end
