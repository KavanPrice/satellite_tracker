defmodule SatelliteTracker do
  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    Process.send_after(self(), :fetch, 0)

    state = %{
      interval: Keyword.get(options, :interval, 1000),
      base_url: Keyword.fetch!(options, :base_url)
    }

    {:ok, state}
  end

  def handle_info(:fetch, state) do
    case get_satellite_summaries(state.base_url) do
      {:ok, satellites} ->
        Enum.map(
          satellites,
          fn satellite ->
            case get_satellite_details(state.base_url, satellite) do
              {:ok, satellite_details} ->
                write_measurement(satellite_details)

              {:error, {:http_request_failed, message}} ->
                Logger.error("Failed to get satellite details: #{inspect(message)}")

              {:error, {:unexpected_error, message}} ->
                Logger.error(
                  "Unexpected error trying to get satellite details: #{inspect(message)}"
                )
            end
          end
        )

        {:noreply, state}

      {:error, reason} ->
        Logger.alert("Error fetching data: #{inspect(reason)}")
        {:noreply, state}
    end

    Process.send_after(self(), :fetch, 1000)
    {:noreply, state}
  end

  @spec get_satellite_summaries(String.t()) :: {:ok, [Satellite.summary_t()]} | {:error, any}
  def get_satellite_summaries(base_url) do
    try do
      case Req.get(base_url <> "/v1/satellites",
             finch: SatelliteTracker.Finch
           ) do
        {:ok, response} ->
          {:ok, Satellite.from_summary_list(response.body)}

        {:error, reason} ->
          {:error, {:http_request_failed, reason}}
      end
    rescue
      e -> {:error, {:unexpected_error, e}}
    end
  end

  @spec get_satellite_details(String.t(), Satellite.summary_t()) ::
          {:ok, Satellite.details_t()}
          | {:error, {:http_request_failed, any()}}
          | {:error, {:unexpected_error, any()}}
  def get_satellite_details(base_url, satellite_summary) do
    satellite_id = satellite_summary.id |> Integer.to_string()

    try do
      case Req.get(
             base_url <>
               "/v1/satellites/" <> satellite_id,
             finch: SatelliteTracker.Finch
           ) do
        {:ok, response} ->
          {:ok, Satellite.from_details(response.body)}

        {:error, reason} ->
          {:error, {:http_request_failed, reason}}
      end
    rescue
      e -> {:error, {:unexpected_error, e}}
    end
  end

  @spec write_measurement(Satellite.details_t()) :: nil
  def write_measurement(satellite_details) do
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
        :ok

      {:error, %{code: "unauthorized", message: message}} ->
        Logger.error("InfluxDB authorization failed: #{message}")
        {:error, :unauthorized}

      {:error, error} ->
        Logger.error("Failed to write to InfluxDB: #{inspect(error, pretty: true)}")
        {:error, :write_failed}

      unexpected ->
        Logger.error("Unexpected response from InfluxDB: #{inspect(unexpected, pretty: true)}")
        {:error, :unexpected_response}
    end
  end
end
