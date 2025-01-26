import Config

config :logger,
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

if config_env() == :prod do
  config :logger,
    level: :debug,
    backends: [:console],
    compile_time_purge_matching: [
      [level_lower_than: :info]
    ]
end

config :satellite_tracker, SatelliteTracker.Connection,
  auth: [method: :token, token: System.get_env("DOCKER_INFLUXDB_INIT_ADMIN_TOKEN")],
  host: "influxdb",
  port: 8086,
  bucket: System.get_env("DOCKER_INFLUXDB_INIT_BUCKET"),
  org: System.get_env("DOCKER_INFLUXDB_INIT_ORG"),
  version: :v2
