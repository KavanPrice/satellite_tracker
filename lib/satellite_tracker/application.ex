defmodule SatelliteTracker.Application do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("Starting SatelliteTracker application...")

    # Log environment variables
    Logger.info(
      "InfluxDB Configuration: #{inspect(%{host: "influxdb", port: 8086, bucket: System.get_env("DOCKER_INFLUXDB_INIT_BUCKET"), org: System.get_env("DOCKER_INFLUXDB_INIT_ORG"), token: System.get_env("DOCKER_INFLUXDB_INIT_ADMIN_TOKEN")})}"
    )

    children = [
      {Finch, name: SatelliteTracker.Finch},
      SatelliteTracker.Connection,
      {SatelliteTracker.Fetcher,
       [
         interval: 39600,
         satellite_ids: [
           62030,
           61447,
           61043,
           60450,
           60378,
           49044,
           36086,
           26700,
           26400,
           25575,
           25544
         ],
         observer_lat: 51.477811,
         observer_lng: -0.001475,
         observer_alt: 0.0,
         num_future_positions: 1,
         base_url: System.get_env("SATELLITE_BASE_URL") |> to_string(),
         api_key: System.get_env("SATELLITE_API_KEY") |> to_string()
       ]},
      SatelliteTracker.Writer
    ]

    opts = [strategy: :one_for_one, name: SatelliteTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
