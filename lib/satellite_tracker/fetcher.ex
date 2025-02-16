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
      satellite_ids: Keyword.get(options, :satellite_ids, [25544]),
      observer_lat: Keyword.get(options, :observer_lat, 0),
      observer_lng: Keyword.get(options, :observer_lng, 0),
      observer_alt: Keyword.get(options, :observer_alt, 0),
      num_future_positions: Keyword.get(options, :num_future_positions, 1),
      base_url: Keyword.fetch!(options, :base_url),
      api_key: Keyword.fetch!(options, :api_key)
    }

    {:ok, state}
  end

  def handle_info(:fetch, state) do
    Enum.each(state.satellite_ids, fn satellite_id ->
      case get_satellite(
             satellite_id,
             state.observer_lat,
             state.observer_lng,
             state.observer_alt,
             state.num_future_positions,
             state.base_url,
             state.api_key
           ) do
        {:ok, satellite} ->
          SatelliteTracker.Writer.write_positions(satellite)

        {:error, details} ->
          Logger.alert(
            "Couldn't get status of satellite " <>
              Integer.to_string(satellite_id) <> ": " <> inspect(details)
          )
      end
    end)

    Process.send_after(self(), :fetch, state.interval)
    {:noreply, state}
  end

  @spec get_satellite(integer(), float(), float(), float(), integer(), String.t(), String.t()) ::
          {:ok, Satellite.t()} | {:error, any}
  defp get_satellite(
         satellite_id,
         observer_lat,
         observer_lng,
         observer_alt,
         num_future_positions,
         base_url,
         api_key
       ) do
    req_url =
      base_url <>
        "/rest/v1/satellite/positions/" <>
        Integer.to_string(satellite_id) <>
        "/" <>
        Float.to_string(observer_lat) <>
        "/" <>
        Float.to_string(observer_lng) <>
        "/" <>
        Float.to_string(observer_alt) <>
        "/" <>
        Integer.to_string(num_future_positions) <>
        "&apiKey=" <>
        api_key

    try do
      case(Req.get(req_url, finch: SatelliteTracker.Finch)) do
        {:ok, response} -> {:ok, Satellite.from_response(response.body)}
        {:error, reason} -> {:error, {:http_request_failed, reason}}
      end
    rescue
      e -> {:error, {:unexpected_error, e}}
    end
  end
end
