defmodule BenchConnect.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Application.get_env(:bench_connect, :enabled, true) do
        [BenchConnect.Publisher]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: BenchConnect.Supervisor)
  end
end
