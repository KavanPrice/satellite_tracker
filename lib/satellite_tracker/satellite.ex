defmodule Satellite do
  @type t :: %__MODULE__{
          info: Info.t(),
          positions: [Position.t()]
        }

  defstruct [
    :info,
    :positions
  ]

  @spec from_response(term()) :: t()
  def from_response(res) do
    %__MODULE__{
      info: res["info"] |> Info.from_term(),
      positions: Enum.map(res["positions"], &Position.from_term/1)
    }
  end
end

defmodule Info do
  @type t :: %__MODULE__{
          satname: String.t(),
          satid: integer(),
          transactionscount: integer()
        }

  defstruct [:satname, :satid, :transactionscount]

  @spec from_term(term()) :: t()
  def from_term(term) do
    %__MODULE__{
      satname: term["satname"],
      satid: term["satid"],
      transactionscount: term["transactionscount"]
    }
  end
end

defmodule Position do
  @type t() :: %__MODULE__{
          satlatitude: float(),
          satlongitude: float(),
          sataltitude: float(),
          azimuth: float(),
          elevation: float(),
          ra: float(),
          dec: float(),
          timestamp: integer(),
          eclipsed: bool()
        }

  defstruct [
    :satlatitude,
    :satlongitude,
    :sataltitude,
    :azimuth,
    :elevation,
    :ra,
    :dec,
    :timestamp,
    :eclipsed
  ]

  @spec from_term(term()) :: t()
  def from_term(term) do
    %__MODULE__{
      satlatitude: term["satlatitude"],
      satlongitude: term["satlongitude"],
      sataltitude: term["sataltitude"],
      azimuth: term["azimuth"],
      elevation: term["elevation"],
      ra: term["ra"],
      dec: term["dec"],
      timestamp: term["timestamp"],
      eclipsed: term["eclipsed"]
    }
  end
end
