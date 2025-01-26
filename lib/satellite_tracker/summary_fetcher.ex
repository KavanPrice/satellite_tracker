defmodule SatelliteTracker.SummaryFetcher do
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
          SatelliteTracker.DetailsFetcher.fetch_details(satellite)
        end)

      {:error, reason} ->
        Logger.alert("Error fetching summaries: #{inspect(reason)}")
    end

    Process.send_after(self(), :fetch, state.interval)
    {:noreply, state}
  end

  @spec get_satellite_summaries(String.t()) :: {:ok, [Satellite.summary_t()]} | {:error, any}
  defp get_satellite_summaries(base_url) do
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
end
