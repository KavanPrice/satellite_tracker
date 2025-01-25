import Config

config :logger,
  level: :info,
  handle_otp_reports: true,
  handle_sasl_reports: true

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

if config_env() == :prod do
  config :logger,
    level: :info,
    backends: [:console],
    compile_time_purge_matching: [
      [level_lower_than: :info]
    ]
end
