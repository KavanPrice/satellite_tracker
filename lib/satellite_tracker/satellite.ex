defmodule Satellite do
  @type summary_t :: %Satellite{
          name: String.t(),
          id: non_neg_integer()
        }

  @type details_t :: %Satellite{
          name: String.t(),
          id: non_neg_integer(),
          latitude: float(),
          longitude: float(),
          altitude: float(),
          velocity: float(),
          visibility: float(),
          footprint: float(),
          timestamp: float(),
          daynum: float(),
          solar_lat: float(),
          solar_lon: float(),
          units: MeasurementUnits.t()
        }
  defstruct [
    :name,
    :id,
    :latitude,
    :longitude,
    :altitude,
    :velocity,
    :visibility,
    :footprint,
    :timestamp,
    :daynum,
    :solar_lat,
    :solar_lon,
    :units
  ]

  @spec from_summary(term()) :: summary_t()
  def from_summary(summary) do
    %__MODULE__{
      name: summary["name"],
      id: summary["id"]
    }
  end

  @spec from_summary_list(term()) :: [summary_t()]
  def from_summary_list(summary_list) do
    Enum.map(summary_list, &__MODULE__.from_summary/1)
  end

  @spec from_details(term()) :: details_t()
  def from_details(details) do
    %__MODULE__{
      name: details["name"],
      id: details["id"],
      latitude: details["latitude"],
      longitude: details["longitude"],
      altitude: details["altitude"],
      velocity: details["velocity"],
      visibility: details["visibility"],
      footprint: details["footprint"],
      timestamp: details["timestamp"],
      daynum: details["daynum"],
      solar_lat: details["solar_lat"],
      solar_lon: details["solar_lon"],
      units: details["units"] |> MeasurementUnits.from_string()
    }
  end

  @spec from_details_list(term()) :: [details_t()]
  def from_details_list(details_list) do
    Enum.map(details_list, &__MODULE__.from_details/1)
  end
end

defmodule MeasurementUnits do
  @type t :: :kilometers | :miles

  @spec from_string(String.t()) :: t()
  def from_string(unit_string) do
    case String.downcase(unit_string) do
      "kilometers" -> :kilometers
      "miles" -> :miles
      _ -> :kilometers
    end
  end

  @spec to_string(t()) :: String.t()
  def to_string(units) do
    case units do
      :kilometers -> "kilometers"
      :miles -> "miles"
    end
  end
end
