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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :ssl, :inets, :crypto],
      mod: {SatelliteTracker.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:req, ">= 0.4.0"},
      {:finch, "~> 0.16"}
    ]
  end
end
