defmodule SatelliteTracker.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: SatelliteTracker.Finch},
      SatelliteTracker.Connection,
      {SatelliteTracker.Fetcher,
       [
         interval: 1000,
         base_url: System.get_env("SATELLITE_BASE_URL") |> to_string()
       ]},
      SatelliteTracker.Writer
    ]

    opts = [strategy: :one_for_one, name: SatelliteTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
