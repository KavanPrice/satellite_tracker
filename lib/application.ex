defmodule SatelliteTracker.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: SatelliteTracker.Finch},
      {SatelliteTracker, [interval: 1000]}
    ]

    opts = [strategy: :one_for_one, name: SatelliteTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
