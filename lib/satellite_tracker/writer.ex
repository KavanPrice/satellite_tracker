defmodule SatelliteTracker.Writer do
  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(_options) do
    {:ok, %{}}
  end

  def write_positions(satellite) do
    GenServer.cast(__MODULE__, {:write, satellite})
  end

  def handle_cast({:write, satellite}, state) do
    tags = %{
      satid: satellite.info.satid |> Integer.to_string()
    }

    Enum.each(satellite.positions, fn positions ->
      point = create_point(satellite.info.satname, tags, positions)

      Logger.debug("Attempting to write data: #{inspect(point, pretty: true)}")

      case SatelliteTracker.Connection.write(point) do
        :ok ->
          Logger.info(
            "Successfully wrote data to InfluxDB for satellite " <>
              Integer.to_string(satellite.info.satid)
          )

        {:error, %{code: "unauthorized", message: message}} ->
          Logger.error("InfluxDB authorization failed: #{message}")

        {:error, error} ->
          Logger.error("Failed to write to InfluxDB: #{inspect(error, pretty: true)}")

        unexpected ->
          Logger.error("Unexpected response from InfluxDB: #{inspect(unexpected, pretty: true)}")
      end
    end)

    {:noreply, state}
  end

  defp create_point(satellite_name, satellite_tags, satellite_position) do
    fields = %{
      satlatitude: satellite_position.satlatitude,
      satlongitude: satellite_position.satlongitude,
      sataltitude: satellite_position.sataltitude,
      azimuth: satellite_position.azimuth,
      elevation: satellite_position.elevation,
      ra: satellite_position.ra,
      dec: satellite_position.dec
    }

    %{
      measurement: satellite_name,
      tags: satellite_tags,
      fields: fields,
      # Convert to nanoseconds from seconds
      timestamp: satellite_position.timestamp * 1_000_000_000
    }
  end
end
