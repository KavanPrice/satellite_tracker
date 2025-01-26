defmodule SatelliteTracker.DetailsFetcher do
  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    state = %{
      base_url: Keyword.fetch!(options, :base_url)
    }

    {:ok, state}
  end

  def fetch_details(satellite) do
    GenServer.cast(__MODULE__, {:fetch, satellite})
  end

  def handle_cast({:fetch, satellite}, state) do
    case get_satellite_details(state.base_url, satellite) do
      {:ok, satellite_details} ->
        SatelliteTracker.Writer.write_measurement(satellite_details)

      {:error, {:http_request_failed, message}} ->
        Logger.error("Failed to get satellite details: #{inspect(message)}")

      {:error, {:unexpected_error, message}} ->
        Logger.error("Unexpected error trying to get satellite details: #{inspect(message)}")
    end

    {:noreply, state}
  end

  @spec get_satellite_details(String.t(), Satellite.summary_t()) ::
          {:ok, Satellite.details_t()}
          | {:error, {:http_request_failed, any()}}
          | {:error, {:unexpected_error, any()}}
  defp get_satellite_details(base_url, satellite_summary) do
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
end
