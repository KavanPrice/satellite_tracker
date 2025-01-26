defmodule SatelliteTracker.Writer do
  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(_options) do
    {:ok, %{}}
  end

  def write_measurement(satellite_details) do
    GenServer.cast(__MODULE__, {:write, satellite_details})
  end

  def handle_cast({:write, satellite_details}, state) do
    fields = %{
      latitude: satellite_details.latitude,
      longitude: satellite_details.longitude,
      altitude: satellite_details.altitude,
      velocity: satellite_details.velocity,
      visibility: satellite_details.visibility,
      footprint: satellite_details.footprint,
      daynum: satellite_details.daynum,
      solar_lat: satellite_details.solar_lat,
      solar_lon: satellite_details.solar_lon
    }

    tags = %{
      id: satellite_details.id |> Integer.to_string(),
      units: satellite_details.units |> MeasurementUnits.to_string()
    }

    point = %{
      measurement: satellite_details.name,
      tags: tags,
      fields: fields,
      timestamp: satellite_details.timestamp * 1_000_000_000
    }

    Logger.debug("Attempting to write data: #{inspect(point, pretty: true)}")

    case SatelliteTracker.Connection.write(point) do
      :ok ->
        Logger.debug("Successfully wrote data to InfluxDB")

      {:error, %{code: "unauthorized", message: message}} ->
        Logger.error("InfluxDB authorization failed: #{message}")

      {:error, error} ->
        Logger.error("Failed to write to InfluxDB: #{inspect(error, pretty: true)}")

      unexpected ->
        Logger.error("Unexpected response from InfluxDB: #{inspect(unexpected, pretty: true)}")
    end

    {:noreply, state}
  end
end
