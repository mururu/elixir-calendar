defrecord DateTime, year: 1970, month: 1, day: 1,
                    hour: 0, minute: 0, second: 0,
                    nanosecond: 0, offset: { 0, 0 }

defmodule Calendar do
  import Calendar.Utils

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
    (time |> new_offset({ 0, 0 }) |> to_seconds) -
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
    diff(a, b) == 0
  end

  @doc """
  is_after?
  """
  def is_after?(a = DateTime[], b = DateTime[]) do
    diff(a, b) > 0
  end

  @doc """
  is_before?
  """
  def is_before?(a = DateTime[], b = DateTime[]) do
    diff(a, b) < 0
  end

  @doc """
  Returns string.
  """
  def format(time = DateTime[], string) do
    do_format(string, time, []) |> :lists.reverse |> Enum.join
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

  defp diff(a = DateTime[], b = DateTime[]) do
    ((new_offset(a, { 0, 0 }) |> to_seconds) * 1000000000 + a.nanosecond) -
      ((new_offset(b, { 0, 0 }) |> to_seconds) * 1000000000 + b.nanosecond)
  end

  defp do_format(<< ?%, ?%, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, ["%"|acc])
  end

  defp do_format(<< ?%, ?A, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [weekday_name(day_of_week(time))|acc])
  end

  defp do_format(<< ?%, ?a, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [weekday_name_s(day_of_week(time))|acc])
  end

  defp do_format(<< ?%, ?B, rest :: bytes >>, time = DateTime[month: month], acc) do
    do_format(rest, time, [month_name(month)|acc])
  end

  defp do_format(<< ?%, ?b, rest :: bytes >>, time = DateTime[month: month], acc) do
    do_format(rest, time, [month_name_s(month)|acc])
  end

  defp do_format(<< ?%, ?C, rest :: bytes >>, time = DateTime[year: year], acc) do
    do_format(rest, time, [div(year, 100)|acc])
  end

  defp do_format(<< ?%, ?c, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_c(time)|acc])
  end

  defp do_format(<< ?%, ?D, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_D(time)|acc])
  end

  defp do_format(<< ?%, ?d, rest :: bytes >>, time = DateTime[day: day], acc) do
    do_format(rest, time, [two(day)|acc])
  end

  defp do_format(<< ?%, ?e, rest :: bytes >>, time = DateTime[day: day], acc) do
    do_format(rest, time, [space_two(day)|acc])
  end

  defp do_format(<< ?%, ?F, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_F(time)|acc])
  end

  defp do_format(<< ?%, ?H, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [two(hour)|acc])
  end

  defp do_format(<< ?%, ?h, rest :: bytes >>, time = DateTime[month: month], acc) do
    do_format(rest, time, [month_name(month)|acc])
  end

  defp do_format(<< ?%, ?I, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [two(hour12(hour))|acc])
  end

  defp do_format(<< ?%, ?j, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [three(day_of_year(time))|acc])
  end

  defp do_format(<< ?%, ?k, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [space_two(hour)|acc])
  end

  defp do_format(<< ?%, ?L, rest :: bytes >>, time = DateTime[nanosecond: nanosecond], acc) do
    do_format(rest, time, [three(div(nanosecond, 1000000))|acc])
  end

  defp do_format(<< ?%, ?l, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [space_two(hour12(hour))|acc])
  end

  defp do_format(<< ?%, ?M, rest :: bytes >>, time = DateTime[minute: minute], acc) do
    do_format(rest, time, [two(minute)|acc])
  end

  defp do_format(<< ?%, ?m, rest :: bytes >>, time = DateTime[month: month], acc) do
    do_format(rest, time, [two(month)|acc])
  end

  defp do_format(<< ?%, ?n, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, ["\n"|acc])
  end

  defp do_format(<< ?%, ?N, rest :: bytes >>, time = DateTime[nanosecond: nanosecond], acc) do
    do_format(rest, time, [build_N(nanosecond, 9)|acc])
  end

  defp do_format(<< ?%, ?P, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [am_pm_s(hour)|acc])
  end

  defp do_format(<< ?%, ?p, rest :: bytes >>, time = DateTime[hour: hour], acc) do
    do_format(rest, time, [am_pm(hour)|acc])
  end

  defp do_format(<< ?%, ?R, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_R(time)|acc])
  end

  defp do_format(<< ?%, ?r, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_r(time)|acc])
  end

  defp do_format(<< ?%, ?S, rest :: bytes >>, time = DateTime[second: second], acc) do
    do_format(rest, time, [two(second)|acc])
  end

  defp do_format(<< ?%, ?s, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_s(time)|acc])
  end

  defp do_format(<< ?%, ?T, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_T(time)|acc])
  end

  defp do_format(<< ?%, ?t, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, ["\t"|acc])
  end

  defp do_format(<< ?%, ?U, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_U(time)|acc])
  end

  defp do_format(<< ?%, ?u, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [day_of_week(time)+1|acc])
  end

  defp do_format(<< ?%, ?V, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_V(time)|acc])
  end

  defp do_format(<< ?%, ?v, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_v(time)|acc])
  end

  defp do_format(<< ?%, ?W, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_W(time)|acc])
  end

  defp do_format(<< ?%, ?w, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [day_of_week(time)|acc])
  end

  defp do_format(<< ?%, ?X, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_X(time)|acc])
  end

  defp do_format(<< ?%, ?x, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [build_x(time)|acc])
  end

  defp do_format(<< ?%, ?Y, rest :: bytes >>, time = DateTime[year: year], acc) do
    do_format(rest, time, [four(year)|acc])
  end

  defp do_format(<< ?%, ?y, rest :: bytes >>, time = DateTime[year: year], acc) do
    do_format(rest, time, [two(year)|acc])
  end

  defp do_format(<< other :: utf8, rest :: bytes >>, time = DateTime[], acc) do
    do_format(rest, time, [<< other :: utf8 >>|acc])
  end

  defp do_format(<<>>, DateTime[], acc) do
    acc
  end

  defp build_c(time = DateTime[year: year, month: month, day: day, hour: hour, minute: minute, second: second]) do
    "#{weekday_name_s(day_of_week(time))} #{month_name(month)} #{space_two(day)} " <>
    "#{two(hour)}:#{two(minute)}:#{two(second)} #{four(year)}"
  end

  defp build_D(DateTime[year: year, month: month, day: day]) do
    "#{two(month)}/#{two(day)}/#{two(year)}"
  end

  defp build_F(DateTime[year: year, month: month, day: day]) do
    "#{four(year)}-#{two(month)}-#{two(day)}"
  end

  defp build_N(nanosecond, digit) when is_integer(digit) do
    valid_nanosecond = nine(nanosecond)
    case digit do
      i when i == 0 or 1 == 9 -> valid_nanosecond
      i when i > 0 and i < 9 -> take_first(valid_nanosecond, digit)
      i when i > 9 -> add_zero(valid_nanosecond, digit - 9)
    end
  end

  defp build_R(DateTime[hour: hour, minute: minute]) do
    "#{two(hour)}:#{two(minute)}"
  end

  defp build_r(DateTime[hour: hour, minute: minute, second: second]) do
    "#{two(hour12(12))}:#{two(minute)}:#{two(second)} #{am_pm(hour)}"
  end

  defp build_s(time = DateTime[]) do
    (time |> new_offset({ 0, 0 }) |> to_seconds) - C.datetime_to_gregorian_seconds({{ 1970, 1, 1 }, { 0, 0, 0 }})
  end

  defp build_T(DateTime[hour: hour, minute: minute, second: second]) do
    "#{two(hour)}:#{two(minute)}:#{two(second)}"
  end

  defp build_U(time = DateTime[year: year]) do
    diff = (time |> day_of_year) - first_sunday_yday(year)
    if diff >= 0 do
      two(div(diff, 7) + 1)
    else
      "00"
    end
  end

  defp first_sunday_yday(year) do
    ny_day = DateTime.new(year: year)
    rem(7 - day_of_week(ny_day), 7) + 1
  end

  defp build_W(time = DateTime[year: year]) do
    diff = (time |> day_of_year) - first_monday_yday(year)
    if diff >= 0 do
      two(div(diff, 7) + 1)
    else
      "00"
    end
  end

  defp first_monday_yday(year) do
    ny_day = DateTime.new(year: year)
    rem(8 - day_of_week(ny_day), 7) + 1
  end

  defp build_X(DateTime[hour: hour, minute: minute, second: second]) do
    "#{two(hour)}:#{two(minute)}:#{two(second)}"
  end

  defp build_x(DateTime[year: year, month: month, day: day]) do
    "#{two(month)}/#{two(day)}/#{two(year)}"
  end

  defp build_V(time = DateTime[year: year, month: month, day: day]) do
    wd = day_of_week(time)
    case { month, day } do
      { 1, 1 } when wd == 0 or wd == 5 or wd == 6 ->
        do_build_V(DateTime[year: year - 1, month: 12, day: 31])
      { 1, 2 } when wd == 0 or wd == 6 ->
        do_build_V(DateTime[year: year - 1, month: 12, day: 31])
      { 1, 3 } when wd == 0 ->
        do_build_V(DateTime[year: year - 1, month: 12, day: 31])
      { 12, 29 } when wd == 1 ->
        do_build_V(DateTime[year: year + 1, month: 1, day: 1])
      { 12, 30 } when wd == 1 or wd == 2 ->
        do_build_V(DateTime[year: year + 1, month: 1, day: 1])
      { 12, 31 } when wd == 1 or wd == 2 or wd == 3 ->
        do_build_V(DateTime[year: year + 1, month: 1, day: 1])
      _ ->
        do_build_V(time)
    end
  end

  defp do_build_V(time = DateTime[year: year]) do
    diff = (time |> day_of_year) - monday_in_first_thursday_week(year)
    two(div(diff, 7) + 1)
  end

  defp monday_in_first_thursday_week(year) do
    ny_day = DateTime.new(year: year)
    rem(11 - day_of_week(ny_day), 7) - 2
  end

  defp build_v(DateTime[year: year, month: month, day: day]) do
    "#{space_two(day)}-#{month_name_s(month)}-#{four(year)}"
  end

  defp hour12(hour) do
    rem(hour + 11, 12) + 1
  end

  defp am_pm_s(hour) do
    if hour < 12, do: "am", else: "pm"
  end

  defp am_pm(hour) do
    if hour < 12, do: "AM", else: "PM"
  end

  def new_offset(time = DateTime[offset: offset], new_o) do
    min = round(offset_to_min(new_o) - offset_to_min(offset))
    time = plus(time, minutes: min)
    time.update(offset: new_o)
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
  import Calendar.Utils

  def inspect(DateTime[year: year, month: month, day: day,
                       hour: hour, minute: minute, second: second, offset: offset], _) do
    ([year, two(month), two(day)] |> Enum.join("-")) <>
    " " <>
    ([two(hour), two(minute), two(second)] |> Enum.join(":")) <>
    offset_inspect(offset)
  end

  defp offset_inspect({ hour, min }) do
    sign = if hour < 0 , do: "-", else: "+"
    sign <> two(abs(hour)) <> ":" <> two(abs(min))
  end
end
