defrecord DateTime, year: 1970, month: 1, day: 1,
                    hour: 0, minute: 0, second: 0,
                    nanosecond: 0, offset: { 0, 0 }

defmodule Calendar do
  alias :calendar, as: C

  @doc """
  Universal Time
  """
  def universal_time do
    { megasecond, second, microsecond } = :erlang.now

    {{ year, month, day }, { hour, minute, second }} =
      C.now_to_universal_time({ megasecond, second, microsecond })

    DateTime.new [year: year, month: month, day: day,
                  hour: hour, minute: minute, second: second,
                  nanosecond: microsecond * 1000, offset: { 0, 0 }]
  end

  @doc """
  Local Time
  """
  def local_time do
    { megasecond, second, microsecond } = :erlang.now

    l = C.now_to_local_time({ megasecond, second, microsecond })
    u = C.now_to_universal_time({ megasecond, second, microsecond })

    offset = calc_offset(l, u)

    {{ year, month, day }, { hour, minute, second }} = l

    DateTime.new [year: year, month: month, day: day,
                  hour: hour, minute: minute, second: second,
                  nanosecond: microsecond * 1000, offset: offset]
  end

  @doc """
  Check whether the datatime is valid or not.
  """
  def valid?(DateTime[year: year, month: month, day: day,
                      hour: hour, minute: minute, second: second,
                      nanosecond: nanosecond, offset: offset]) do
    valid_date?(year, month, day) &&
    valid_hour?(hour) &&
    valid_minute?(minute) &&
    valid_second?(second) &&
    valid_nanosecond?(nanosecond) &&
    valid_offset?(offset)
  end

  @doc """
  DateTime -> tuple.
  """
  def to_tuple(DateTime[year: year, month: month, day: day,
                        hour: hour, minute: minute, second: second]) do
    {{ year, month, day }, { hour, minute, second }}
  end

  @doc """
  tuple -> DateTime
  """
  def from_tuple({{ year, month, day }, { hour, minute, second }}) do
    DateTime[year: year, month: month, day: day,
             hour: hour, minute: minute, second: second]
  end

  @doc """
  DateTime -> unix_time
  """
  def to_unix_time(time = DateTime[]) do
    (time |> change_offset({ 0, 0 }) |> to_seconds) -
      C.datetime_to_gregorian_seconds({{ 1970, 1, 1 }, { 0, 0, 0 }})
  end

  @doc """
  unix_time -> DateTime
  """
  def from_unix_time(seconds) do
    (seconds + C.datetime_to_gregorian_seconds({{ 1970, 1, 1 }, { 0, 0, 0 }}))
    |> C.gregorian_seconds_to_datetime
    |> from_tuple
  end

  @doc """
  plus
  """
  def plus(time = DateTime[], list) do
    list = Keyword.merge([years: 0, months: 0, days: 0,
                          hours: 0, minutes: 0, seconds: 0], list)
    do_plus(time, [ list[:years], list[:months], list[:days],
                    list[:hours], list[:minutes], list[:seconds] ])
  end

  @doc """
  minus
  """
  def minus(time = DateTime[], list) do
    list = Keyword.merge([years: 0, months: 0, days: 0,
                          hours: 0, minutes: 0, seconds: 0], list)
    do_minus(time, [ list[:years], list[:months], list[:days],
                     list[:hours], list[:minutes], list[:seconds] ])
  end

  @doc """
  equal?
  """
  def equal?(a = DateTime[], b = DateTime[]) do
    diff_nano(a, b) == 0
  end

  @doc """
  is_after?
  """
  def is_after?(a = DateTime[], b = DateTime[]) do
    diff_nano(a, b) > 0
  end

  @doc """
  is_before?
  """
  def is_before?(a = DateTime[], b = DateTime[]) do
    diff_nano(a, b) < 0
  end

  @doc """
  Change offset.
  """
  def change_offset(time = DateTime[offset: offset], new_o) do
    min = round(offset_to_min(new_o) - offset_to_min(offset))
    time = plus(time, minutes: min)
    time.update(offset: new_o)
  end

  @doc """
  Returns string.
  """
  def format(time = DateTime[], string) do
    do_format(time, string)
  end

  @doc """
  diff seconds
  """
  def diff(DateTime[] = t1, DateTime[] = t2) do
    seconds1 = t1 |> change_offset({ 0, 0 }) |> to_seconds
    seconds2 = t2 |> change_offset({ 0, 0 }) |> to_seconds
    seconds1 - seconds2
  end

  ## private

  defp calc_offset(local, universal) do
    ls = local |> from_tuple |> to_seconds
    us = universal |> from_tuple |> to_seconds
    min = div(ls , 60) - div(us, 60)
    h = div(abs(min), 60)
    m = rem(abs(min), 60)
    if min >= 0, do: { h, m }, else: { -h, m }
  end

  defp valid_hour?(hour) do
    hour >= 0 && hour <= 23
  end

  defp valid_minute?(minute) do
    minute >= 0 && minute <= 59
  end

  defp valid_second?(second) do
    second >= 0 && second <= 59
  end

  defp valid_nanosecond?(nanosecond) do
    nanosecond >= 0 && nanosecond <= 999999999
  end

  defp valid_date?(year, month, day) do
    C.valid_date(year, month, day)
  end

  defp valid_offset?({ _, min }) do
    valid_minute?(min)
  end

  defp seconds_after(time = DateTime[nanosecond: nanosecond, offset: offset], second) do
    time = (to_seconds(time) + second)
           |> C.gregorian_seconds_to_datetime
           |> from_tuple

    time.update(nanosecond: nanosecond, offset: offset)
  end

  defp to_seconds(time = DateTime[]) do
    C.datetime_to_gregorian_seconds(to_tuple(time))
  end

  defp do_plus(time = DateTime[], [years, months, days, hours, minutes, seconds]) do
    s = seconds + minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60
    time = seconds_after(time, s)
    m = time.month + months
    month = rem(m - 1, 12) + 1
    year = time.year + years + div(m - 1, 12)
    time.update(year: year, month: month)
  end

  defp do_minus(time = DateTime[], list) do
    list = Enum.map(list, -&1)
    do_plus(time, list)
  end

  defp day_of_week(DateTime[year: year, month: month, day: day]) do
    C.day_of_the_week({ year, month, day }) |> convert_day_of_week
  end

  def day_of_year(DateTime[year: year, month: month, day: day]) do
    day +
      if leap_year_y?(year) do
        leap_year_yday_offset(month)
      else
        common_year_yday_offset(month)
      end
  end

  defp leap_year_y?(year) do
    rem(year, 4) == 0 && rem(year, 100) != 0 || rem(year, 400) == 0
  end

  defp diff_nano(a = DateTime[], b = DateTime[]) do
    ((change_offset(a, { 0, 0 }) |> to_seconds) * 1000000000 + a.nanosecond) -
      ((change_offset(b, { 0, 0 }) |> to_seconds) * 1000000000 + b.nanosecond)
  end

  defp do_format(DateTime[year: year] = t, "YYYY" <> rest) do
    integer_to_binary(year) <> do_format(t, rest)
  end

  defp do_format(DateTime[year: year] = t, "YY" <> rest) do
    just_two_digit(rem(year, 100)) <> do_format(t, rest)
  end

  defp do_format(DateTime[month: month] = t, "MMMM" <> rest) do
    month_name(month) <> do_format(t, rest)
  end

  defp do_format(DateTime[month: month] = t, "MMM" <> rest) do
    month_name_s(month) <> do_format(t, rest)
  end

  defp do_format(DateTime[month: month] = t, "MM" <> rest) do
    just_two_digit(month) <> do_format(t, rest)
  end

  defp do_format(DateTime[month: month] = t, "M" <> rest) do
    integer_to_binary(month) <> do_format(t, rest)
  end

  defp do_format(DateTime[day: day] = t, "dd" <> rest) do
    just_two_digit(day) <> do_format(t, rest)
  end

  defp do_format(DateTime[day: day] = t, "d" <> rest) do
    integer_to_binary(day) <> do_format(t, rest)
  end

  defp do_format(DateTime[] = t, "EEEE" <> rest) do
    weekday_name(day_of_week(t)) <> do_format(t, rest)
  end

  defp do_format(DateTime[] = t, "EE" <> rest) do
    weekday_name_s(day_of_week(t)) <> do_format(t, rest)
  end

  defp do_format(DateTime[hour: hour] = t, "hh" <> rest) do
    hour = rem(hour, 12)
    just_two_digit(hour) <> do_format(t, rest)
  end

  defp do_format(DateTime[hour: hour] = t, "h" <> rest) do
    hour = rem(hour, 12)
    integer_to_binary(hour) <> do_format(t, rest)
  end

  defp do_format(DateTime[hour: hour] = t, "HH" <> rest) do
    just_two_digit(hour) <> do_format(t, rest)
  end

  defp do_format(DateTime[hour: hour] = t, "H" <> rest) do
    integer_to_binary(hour) <> do_format(t, rest)
  end

  defp do_format(DateTime[hour: hour] = t, "a" <> rest) do
    label = if hour < 12, do: "AM", else: "PM"
    label <> do_format(t, rest)
  end

  defp do_format(DateTime[minute: minute] = t, "mm" <> rest) do
    just_two_digit(minute) <> do_format(t, rest)
  end

  defp do_format(DateTime[minute: minute] = t, "m" <> rest) do
    integer_to_binary(minute) <> do_format(t, rest)
  end

  defp do_format(DateTime[second: second] = t, "ss" <> rest) do
    just_two_digit(second) <> do_format(t, rest)
  end

  defp do_format(DateTime[second: second] = t, "s" <> rest) do
    integer_to_binary(second) <> do_format(t, rest)
  end

  defp do_format(DateTime[nanosecond: nanosecond] = t, "SSS" <> rest) do
    just_three_digit(div(nanosecond, 1000)) <> do_format(t, rest)
  end

  defp do_format(DateTime[nanosecond: nanosecond] = t, "SS" <> rest) do
    just_two_digit(div(nanosecond, 10000)) <> do_format(t, rest)
  end

  defp do_format(DateTime[nanosecond: nanosecond] = t, "S" <> rest) do
    integer_to_binary(div(nanosecond, 100000)) <> do_format(t, rest)
  end

  defp do_format(DateTime[offset: { hour, minute }] = t, "ZZ" <> rest) do
    sign = if hour >= 0, do: "+", else: "-"
    "#{sign}#{just_two_digit(abs(hour))}:#{just_two_digit(minute)}" <> do_format(t, rest)
  end

  defp do_format(DateTime[offset: { hour, minute }] = t, "Z" <> rest) do
    sign = if hour >= 0, do: "+", else: "-"
    "#{sign}#{just_two_digit(abs(hour))}#{just_two_digit(minute)}" <> do_format(t, rest)
  end

  defp do_format(DateTime[] = t, "''" <> rest) do
    "'" <> do_format(t, rest)
  end

  defp do_format(DateTime[] = t, "'" <> rest) do
    do_format_escape(t, rest)
  end

  defp do_format(DateTime[] = t, << h, rest :: binary >>) when not (h in ?a..?z or h in ?A..?Z) do
    << h, do_format(t, rest) :: binary >>
  end

  defp do_format(DateTime[], <<>>) do
    <<>>
  end

  defp do_format_escape(DateTime[] = t, "'" <> rest) do
    do_format(t, rest)
  end

  defp do_format_escape(DateTime[] = t, << h, rest :: binary >>) do
    << h, do_format_escape(t, rest) :: binary >>
  end

  defp do_format_escape(DateTime[], <<>>) do
    <<>>
  end

  defp just_two_digit(n) when n < 10 do
    "0" <> integer_to_binary(n)
  end

  defp just_two_digit(n) do
    integer_to_binary(n)
  end

  defp just_three_digit(n) when n < 10 do
    "00" <> integer_to_binary(n)
  end

  defp just_three_digit(n) when n < 100 do
    "0" <> integer_to_binary(n)
  end

  defp just_three_digit(n) do
    integer_to_binary(n)
  end

  defp offset_to_min({ hour, min }) do
    m = abs(hour) * 60 + min
    if hour >= 0, do: m, else: -m
  end

  defp weekday_name(0), do: "Sunday"
  defp weekday_name(1), do: "Monday"
  defp weekday_name(2), do: "Tuesday"
  defp weekday_name(3), do: "Wednesday"
  defp weekday_name(4), do: "Thursday"
  defp weekday_name(5), do: "Friday"
  defp weekday_name(6), do: "Saturday"

  defp weekday_name_s(0), do: "Sun"
  defp weekday_name_s(1), do: "Mon"
  defp weekday_name_s(2), do: "Tue"
  defp weekday_name_s(3), do: "Wed"
  defp weekday_name_s(4), do: "Thu"
  defp weekday_name_s(5), do: "Fri"
  defp weekday_name_s(6), do: "Sat"

  defp month_name(1),  do: "January"
  defp month_name(2),  do: "Feburuary"
  defp month_name(3),  do: "March"
  defp month_name(4),  do: "April"
  defp month_name(5),  do: "May"
  defp month_name(6),  do: "June"
  defp month_name(7),  do: "July"
  defp month_name(8),  do: "August"
  defp month_name(9),  do: "September"
  defp month_name(10), do: "October"
  defp month_name(11), do: "November"
  defp month_name(12), do: "December"

  defp month_name_s(1),  do: "Jan"
  defp month_name_s(2),  do: "Feb"
  defp month_name_s(3),  do: "Mar"
  defp month_name_s(4),  do: "Apr"
  defp month_name_s(5),  do: "May"
  defp month_name_s(6),  do: "Jun"
  defp month_name_s(7),  do: "Jul"
  defp month_name_s(8),  do: "Aug"
  defp month_name_s(9),  do: "Sep"
  defp month_name_s(10), do: "Oct"
  defp month_name_s(11), do: "Nov"
  defp month_name_s(12), do: "Dec"

  defp convert_day_of_week(1), do: 1
  defp convert_day_of_week(2), do: 2
  defp convert_day_of_week(3), do: 3
  defp convert_day_of_week(4), do: 4
  defp convert_day_of_week(5), do: 5
  defp convert_day_of_week(6), do: 6
  defp convert_day_of_week(7), do: 0

  defp common_year_yday_offset(1),  do: 0
  defp common_year_yday_offset(2),  do: 31
  defp common_year_yday_offset(3),  do: 59
  defp common_year_yday_offset(4),  do: 90
  defp common_year_yday_offset(5),  do: 120
  defp common_year_yday_offset(6),  do: 151
  defp common_year_yday_offset(7),  do: 181
  defp common_year_yday_offset(8),  do: 212
  defp common_year_yday_offset(9),  do: 243
  defp common_year_yday_offset(10), do: 273
  defp common_year_yday_offset(11), do: 304
  defp common_year_yday_offset(12), do: 334

  defp leap_year_yday_offset(1),  do: 0
  defp leap_year_yday_offset(2),  do: 31
  defp leap_year_yday_offset(3),  do: 60
  defp leap_year_yday_offset(4),  do: 91
  defp leap_year_yday_offset(5),  do: 121
  defp leap_year_yday_offset(6),  do: 152
  defp leap_year_yday_offset(7),  do: 182
  defp leap_year_yday_offset(8),  do: 213
  defp leap_year_yday_offset(9),  do: 244
  defp leap_year_yday_offset(10), do: 274
  defp leap_year_yday_offset(11), do: 305
  defp leap_year_yday_offset(12), do: 335
end

defimpl Binary.Inspect, for: DateTime do
  import Kernel, except: [inspect: 2]

  def inspect(DateTime[year: year, month: month, day: day,
                       hour: hour, minute: minute, second: second, offset: offset], _) do
    ([year, just_two_digit(month), just_two_digit(day)] |> Enum.join("-")) <>
    " " <>
    ([just_two_digit(hour), just_two_digit(minute), just_two_digit(second)] |> Enum.join(":")) <>
    offset_inspect(offset)
  end

  defp offset_inspect({ hour, min }) do
    sign = if hour < 0 , do: "-", else: "+"
    sign <> just_two_digit(abs(hour)) <> ":" <> just_two_digit(abs(min))
  end

  defp just_two_digit(n) when n < 10 do
    "0" <> integer_to_binary(n)
  end

  defp just_two_digit(n) do
    integer_to_binary(n)
  end
end
