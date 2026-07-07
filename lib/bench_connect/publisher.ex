defmodule BenchConnect.Publisher do
  @moduledoc """
  Registers the `_flash-bench-device._tcp` service with `MdnsLite` on boot.

  Advertising itself (interface monitoring, responding to queries) is
  `mdns_lite`'s job — this process only has to get the service into its
  table. Registration is retried with backoff so a transient `mdns_lite`
  restart or slowly-appearing identity data (e.g. `Nerves.Runtime.KV` still
  loading) can't leave the device unadvertised.
  """

  use GenServer
  require Logger

  # After exhausting the list, keep retrying at the last interval.
  @retry_intervals [1_000, 2_000, 5_000, 10_000, 30_000]

  # Attempts to wait for a usable identity (a real serial or a hw_serial)
  # before publishing whatever is derivable anyway.
  @identity_grace_attempts 3

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Re-derive the TXT records and replace the advertisement."
  @spec republish() :: :ok
  def republish, do: GenServer.cast(__MODULE__, :republish)

  @impl true
  def init(_opts) do
    {:ok, %{attempt: 0}, {:continue, :publish}}
  end

  @impl true
  def handle_continue(:publish, state), do: attempt_publish(state)

  @impl true
  def handle_info(:publish, state), do: attempt_publish(state)

  @impl true
  def handle_cast(:republish, state) do
    # Re-adding a service whose TXT changed would leave both records in
    # mdns_lite's table, so drop the old one first.
    safely(fn -> MdnsLite.remove_mdns_service(BenchConnect.service_id()) end)
    attempt_publish(%{state | attempt: 0})
  end

  defp attempt_publish(state) do
    txt_payload = safe_txt_payload()

    cond do
      not identity_ready?(txt_payload) and state.attempt < @identity_grace_attempts ->
        Logger.debug("[bench_connect] identity not derivable yet, retrying")
        retry(state)

      publish(txt_payload) == :ok ->
        Logger.info(
          "[bench_connect] advertising #{BenchConnect.service_type()} #{inspect(txt_payload)}"
        )

        {:noreply, state}

      true ->
        retry(state)
    end
  end

  defp publish(txt_payload) do
    service = %{
      id: BenchConnect.service_id(),
      protocol: BenchConnect.protocol(),
      transport: "tcp",
      port: 0,
      txt_payload: txt_payload
    }

    case safely(fn -> MdnsLite.add_mdns_service(service) end) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.warning("[bench_connect] failed to register service: #{inspect(reason)}")
        :error
    end
  end

  defp retry(state) do
    Process.send_after(self(), :publish, retry_interval(state.attempt))
    {:noreply, %{state | attempt: state.attempt + 1}}
  end

  defp retry_interval(attempt) do
    Enum.at(@retry_intervals, attempt, List.last(@retry_intervals))
  end

  # The bench correlates devices by serial/hw_serial, so give identity
  # derivation a moment before advertising without either. "unconfigured" is
  # nerves_runtime's placeholder for a serial it couldn't read.
  defp identity_ready?(txt_payload) do
    Enum.any?(txt_payload, fn entry ->
      String.starts_with?(entry, "hw_serial=") or
        (String.starts_with?(entry, "serial=") and entry != "serial=unconfigured")
    end)
  end

  defp safe_txt_payload do
    BenchConnect.Info.txt_payload()
  rescue
    exception ->
      Logger.warning("[bench_connect] deriving TXT records failed: #{inspect(exception)}")
      []
  end

  # MdnsLite's API calls into its TableServer; if mdns_lite is (re)starting
  # the call exits with :noproc — report it as an error instead of crashing.
  defp safely(fun) do
    fun.()
  catch
    :exit, reason -> {:error, reason}
  end
end
