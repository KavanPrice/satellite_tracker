defmodule MeasurementUnitsTest do
  use ExUnit.Case
  doctest MeasurementUnits

  test "unit from string" do
    assert MeasurementUnits.from_string("kilometers") == :kilometers
    assert MeasurementUnits.from_string("miles") == :miles
    assert_raise ArgumentError, fn -> MeasurementUnits.from_string("") end
  end

  test "unit to string" do
    assert MeasurementUnits.to_string(:kilometers) == "kilometers"
    assert MeasurementUnits.to_string(:miles) == "miles"
  end

  test "full unit conversion" do
    assert :kilometers
           |> MeasurementUnits.to_string()
           |> MeasurementUnits.from_string() ==
             :kilometers

    assert :miles
           |> MeasurementUnits.to_string()
           |> MeasurementUnits.from_string() ==
             :miles
  end
end
