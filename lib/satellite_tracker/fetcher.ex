defmodule SatelliteTracker.Fetcher do
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
        Enum.each(satellites, fn satellite ->
          case get_satellite_details(state.base_url, satellite) do
            {:ok, satellite_details} ->
              SatelliteTracker.Writer.write_measurement(satellite_details)

            {:error, {:http_request_failed, message}} ->
              Logger.error("Failed to get satellite details: #{inspect(message)}")

            {:error, {:unexpected_error, message}} ->
              Logger.error(
                "Unexpected error trying to get satellite details: #{inspect(message)}"
              )
          end
        end)

      {:error, reason} ->
        Logger.alert("Error fetching data: #{inspect(reason)}")
    end

    Process.send_after(self(), :fetch, state.interval)
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
end
