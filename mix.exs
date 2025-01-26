defmodule SatelliteTracker.MixProject do
  use Mix.Project

  def project do
    [
      app: :satellite_tracker,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :inets, :crypto],
      mod: {SatelliteTracker.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.4.14"},
      {:finch, "~> 0.19.0"},
      {:castore, "~> 1.0.11"},
      {:jason, "~> 1.4.4"},
      {:jsone, "~> 1.4.3"},
      {:instream, "~> 2.2.1"}
    ]
  end
end
