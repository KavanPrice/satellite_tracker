defmodule SatelliteTracker do
  use GenServer
  require Logger

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, options, name: __MODULE__)
  end

  def init(options) do
    Process.send_after(self(), :fetch, 0)

    {:ok, %{interval: Keyword.get(options, :interval, 1000)}}
  end

  def handle_info(:fetch, state) do
    case get_satellite_summaries() do
      {:ok, satellites} ->
        Enum.map(satellites, &get_satellite_details/1)
        |> print_satellites()

        {:noreply, state}

      {:error, reason} ->
        Logger.alert("Error fetching data: #{inspect(reason)}")
        {:noreply, state}
    end

    Process.send_after(self(), :fetch, 1000)
    {:noreply, state}
  end

  @spec get_satellite_summaries() :: {:ok, [Satellite.summary_t()]} | {:error, any}
  def get_satellite_summaries() do
    try do
      case Req.get(System.get_env("SATELLITE_BASE_URL") <> "/v1/satellites",
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

  @spec get_satellite_details(Satellite.summary_t()) :: {:ok, Satellite.details_t()}
  def get_satellite_details(satellite_summary) do
    satellite_id = satellite_summary.id |> Integer.to_string()

    try do
      case Req.get(
             (System.get_env("SATELLITE_BASE_URL") |> to_string) <>
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

  defp print_satellites(satellite_list) do
    Enum.map(satellite_list, &print_satellite/1)
  end

  defp print_satellite(satellite) do
    Logger.info("Satellite data: #{inspect(satellite)}")
  end
end
