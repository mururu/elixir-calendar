defrecord DateTime, year: nil, month: nil, day: nil, hour: nil, minute: nil, sec: nil do
  @days_of_week_name [{ 0, "Sunday" }, { 1, "Monday" }, { 2, "Tuesday" }, { 3, "Wednesday" }, { 4, "Thursday" }, { 5, "Friday" }, { 6, "saturday" }]
  @days_of_week_name_short [{ 0, "Sun" }, { 1, "Mon" }, { 2, "Tue" }, { 3, "Wed" }, { 4, "Thu" }, { 5, "Fri" }, { 6, "sat" }]
  @month_name [{ 1, "January" }, { 2, "February" }, { 3, "March" }, { 4, "April" }, { 5, "May" }, { 6, "June" }, { 7, "July" }, { 8, "August" }, { 9, "September" }, { 10, "October" }, { 11, "November" }, { 12, "December" }]
  @month_name_short [{ 1, "Jan" }, { 2, "Feb" }, { 3, "Mar" }, { 4, "Apr" }, { 5, "May" }, { 6, "Jun" }, { 7, "Jul" }, { 8, "Aug" }, { 9, "Sep" }, { 10, "Oct" }, { 11, "Nov" }, { 12, "Dec" }]
  @common_year_yday_offset [
    { 1,  -1 },
    { 2,  -1 + 31 },
    { 3,  -1 + 31 + 28 },
    { 4,  -1 + 31 + 28 + 31 },
    { 5,  -1 + 31 + 28 + 31 + 30 },
    { 6,  -1 + 31 + 28 + 31 + 30 + 31 },
    { 7,  -1 + 31 + 28 + 31 + 30 + 31 + 30 },
    { 8,  -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 },
    { 9,  -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 },
    { 10, -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 },
    { 11, -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 },
    { 12, -1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 }
  ]
  @leap_year_yday_offset [
    { 1,  -1 },
    { 2,  -1 + 31 },
    { 3,  -1 + 31 + 29 },
    { 4,  -1 + 31 + 29 + 31 },
    { 5,  -1 + 31 + 29 + 31 + 30 },
    { 6,  -1 + 31 + 29 + 31 + 30 + 31 },
    { 7,  -1 + 31 + 29 + 31 + 30 + 31 + 30 },
    { 8,  -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 },
    { 9,  -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 },
    { 10, -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 },
    { 11, -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 },
    { 12, -1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 }
  ]

  def now do
    {{ year, month, day }, { hour, minute, sec }} = :calendar.local_time
    new [year: year, month: month, day: day, hour: hour, minute: minute, sec: sec]
  end

  def wday(DateTime[year: year, month: month, day: day]) do
    a = div((14 - month), 12)
    ye = year + 4800 - a
    mo = month + 12 * a - 3
    w = day + div((153*mo + 2), 5) + 365*ye + div(ye, 4) - div(ye, 100) + div(ye, 400) + 2
    rem(w, 7)
  end

  def yday(DateTime[year: year, month: month, day: day]) do
    day +
      if leap_year_y?(year) do
        @leap_year_yday_offset[month]
      else
        @common_year_yday_offset[month]
      end
  end

  def leap_year_y?(year) do
    rem(year, 4) == 0 && rem(year, 100) != 0 || rem(year, 400) == 0
  end
end

defmodule DateTime.Utils do
  def two(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      1 -> "0" <> string
      _ -> string
    end
  end
end

defimpl Binary.Inspect, for: DateTime do
  import Kernel, except: [inspect: 2]
  import DateTime.Utils

  def inspect(DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec], _) do
    [year, two(month), two(day)] |> Enum.join("-") <>
    " " <>
    [two(hour), two(minute), two(sec)] |> Enum.join(":")
  end
end
