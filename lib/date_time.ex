defmodule DateTime.Utils do
  def space_two(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      0 -> "  "
      1 -> " " <> string
      2 -> string
      _ -> take_last(string, 2)
    end
  end

  def two(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      0 -> "00"
      1 -> "0" <> string
      2 -> string
      _ -> take_last(string, 2)
    end
  end

  def three(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      0 -> "000" <> string
      1 -> "00" <> string
      2 -> "0" <> string
      3 -> string
      _ -> take_last(string, 3)
    end
  end

  def four(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      0 -> "0000"
      1 -> "000" <> string
      2 -> "00" <> string
      3 -> "0" <> string
      4 -> string
      _ -> take_last(string, 4)
    end
  end

  def nine(int) do
    string = integer_to_binary(int)
    case String.length(string) do
      0 -> "000000000"
      1 -> "00000000" <> string
      2 -> "0000000" <> string
      3 -> "000000" <> string
      4 -> "00000" <> string
      5 -> "0000" <> string
      6 -> "000" <> string
      7 -> "00" <> string
      8 -> "0" <> string
      9 -> string
      _ -> take_last(string, 9)
    end
  end

  def take_first(str, num) do
    String.codepoints(str) |> Enum.take(num) |> Enum.join
  end

  def take_last(str, num) do
    String.codepoints(str) |> Enum.reverse |> Enum.take(num) |> Enum.reverse |> Enum.join
  end

  def add_zero(str, num) do
    str <> String.duplicate("0", num)
  end
end

defrecord DateTime, year: 1970, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 } do
  import DateTime.Utils

  @days_of_week_name [{ 0, "Sunday" }, { 1, "Monday" }, { 2, "Tuesday" }, { 3, "Wednesday" }, { 4, "Thursday" }, { 5, "Friday" }, { 6, "saturday" }]
  @days_of_week_name_short [{ 0, "Sun" }, { 1, "Mon" }, { 2, "Tue" }, { 3, "Wed" }, { 4, "Thu" }, { 5, "Fri" }, { 6, "sat" }]
  @month_name [{ 1, "January" }, { 2, "February" }, { 3, "March" }, { 4, "April" }, { 5, "May" }, { 6, "June" }, { 7, "July" }, { 8, "August" }, { 9, "September" }, { 10, "October" }, { 11, "November" }, { 12, "December" }]
  @month_name_short [{ 1, "Jan" }, { 2, "Feb" }, { 3, "Mar" }, { 4, "Apr" }, { 5, "May" }, { 6, "Jun" }, { 7, "Jul" }, { 8, "Aug" }, { 9, "Sep" }, { 10, "Oct" }, { 11, "Nov" }, { 12, "Dec" }]
  @common_year_yday_offset [
    { 1,  0 },
    { 2,  0 + 31 },
    { 3,  0 + 31 + 28 },
    { 4,  0 + 31 + 28 + 31 },
    { 5,  0 + 31 + 28 + 31 + 30 },
    { 6,  0 + 31 + 28 + 31 + 30 + 31 },
    { 7,  0 + 31 + 28 + 31 + 30 + 31 + 30 },
    { 8,  0 + 31 + 28 + 31 + 30 + 31 + 30 + 31 },
    { 9,  0 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 },
    { 10, 0 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 },
    { 11, 0 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 },
    { 12, 0 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 }
  ]
  @leap_year_yday_offset [
    { 1,  0 },
    { 2,  0 + 31 },
    { 3,  0 + 31 + 29 },
    { 4,  0 + 31 + 29 + 31 },
    { 5,  0 + 31 + 29 + 31 + 30 },
    { 6,  0 + 31 + 29 + 31 + 30 + 31 },
    { 7,  0 + 31 + 29 + 31 + 30 + 31 + 30 },
    { 8,  0 + 31 + 29 + 31 + 30 + 31 + 30 + 31 },
    { 9,  0 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 },
    { 10, 0 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 },
    { 11, 0 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 },
    { 12, 0 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 }
  ]

  def now do
    { megasec, sec, microsec } = :erlang.now
    l = :calendar.now_to_local_time({ megasec, sec, microsec })
    u = :calendar.now_to_universal_time({ megasec, sec, microsec })
    offset = calc_offset(l, u)
    {{ year, month, day }, { hour, minute, sec }} = l
    new [year: year, month: month, day: day, hour: hour, minute: minute, sec: sec, nanosec: microsec * 1000, offset: offset]
  end

  defp calc_offset(local, universal) do
    ls = local |> new_from_erlang |> to_secs
    us = universal |> new_from_erlang |> to_secs
    min = div(ls , 60) - div(us, 60)
    h = div(abs(min), 60)
    m = rem(abs(min), 60)
    if min >= 0, do: { h, m }, else: { -h, m }
  end

  def valid?(DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec, nanosec: nanosec, offset: offset]) do
    valid_hour?(hour) && valid_minute?(minute) && valid_sec?(sec) && valid_nanosec?(nanosec) && valid_offset?(offset) && valid_date?(year, month, day)
  end

  defp valid_hour?(hour) do
    hour >= 0 && hour <= 23
  end

  defp valid_minute?(minute) do
    minute >= 0 && minute <= 59
  end

  def valid_sec?(sec) do
    sec >= 0 && sec <= 59
  end

  def valid_nanosec?(nanosec) do
    nanosec >= 0 && nanosec <= 999999999
  end

  defp valid_date?(year, month, day) do
    :calendar.valid_date(year, month, day)
  end

  defp valid_offset?({ _, min }) do
    valid_minute?(min)
  end

  def to_erlang(DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec]) do
    {{ year, month, day }, { hour, minute, sec }}
  end

  def new_from_erlang({{ year, month, day }, { hour, minute, sec }}) do
    DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec]
  end

  def to_secs(time = DateTime[]) do
    :calendar.datetime_to_gregorian_seconds(time.to_erlang)
  end

  def secs_after(sec, time = DateTime[nanosec: nanosec, offset: offset]) when is_integer(sec) do
    time = (time.to_secs + sec) |> :calendar.gregorian_seconds_to_datetime |> new_from_erlang
    time.update(nanosec: nanosec, offset: offset)
  end

  @doc """
      t = DateTime.now
      #=> 2013-04-19 23:44:32
      t.plus(months: 2, minutes: 4)
  """
  def plus(list, time = DateTime[]) do
    list = Keyword.merge([years: 0, months: 0, days: 0, hours: 0, minutes: 0, secs: 0], list)
    do_plus([years: list[:years], months: list[:months], days: list[:days], hours: list[:hours], minutes: list[:minutes], secs: list[:secs]], time)
  end

  def minus(list, time = DateTime[]) do
    list = Keyword.merge([years: 0, months: 0, days: 0, hours: 0, minutes: 0, secs: 0], list)
    do_minus([years: list[:years], months: list[:months], days: list[:days], hours: list[:hours], minutes: list[:minutes], secs: list[:secs]], time)
  end

  defp do_plus([years: years, months: months, days: days, hours: hours, minutes: minutes, secs: secs], time = DateTime[]) when is_integer(years) and is_integer(months) and is_integer(days) and is_integer(hours) and is_integer(minutes) and is_integer(secs) do
    s = secs + minutes * 60 + hours * 60 * 60 + days * 24 * 60 * 60
    time = time.secs_after(s)
    m = time.month + months
    month = rem(m - 1, 12) + 1
    year = time.year + years + div(m - 1, 12)
    time.update(year: year, month: month)
  end

  defp do_minus(list = [years: years, months: months, days: days, hours: hours, minutes: minutes, secs: secs], time = DateTime[]) when is_integer(years) and is_integer(months) and is_integer(days) and is_integer(hours) and is_integer(minutes) and is_integer(secs) do
    Enum.map(list, fn({ k, v })-> { k, -v } end) |> do_plus(time)
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

  def equal?(a = DateTime[], b = DateTime[]) do
    diff(a, b) == 0
  end

  def is_after?(a = DateTime[], b = DateTime[]) do
    diff(a, b) < 0
  end

  def is_before?(a = DateTime[], b = DateTime[]) do
    diff(a, b) > 0
  end

  defp diff(a = DateTime[], b = DateTime[]) do
    (a.new_offset({ 0, 0 }).to_secs * 1000000000 + a.nanosec) - (b.new_offset({ 0, 0 }).to_secs * 1000000000 + b.nanosec)
  end

  def strftime(string, time = DateTime[]) do
    do_strftime(string, time, []) |> Enum.reverse |> Enum.join
  end

  defp do_strftime(<< ?%, ?%, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, ["%"|acc])
  defp do_strftime(<< ?%, ?A, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [@days_of_week_name[wday(time)]|acc])
  defp do_strftime(<< ?%, ?a, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [@days_of_week_name_short[wday(time)]|acc])
  defp do_strftime(<< ?%, ?B, rest :: bytes >>, time = DateTime[month: month], acc), do: do_strftime(rest, time, [@month_name[month]|acc])
  defp do_strftime(<< ?%, ?b, rest :: bytes >>, time = DateTime[month: month], acc), do: do_strftime(rest, time, [@month_name_short[month]|acc])
  defp do_strftime(<< ?%, ?C, rest :: bytes >>, time = DateTime[year: year], acc), do: do_strftime(rest, time, [div(year, 100)|acc])
  defp do_strftime(<< ?%, ?c, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_c(time)|acc])
  defp do_strftime(<< ?%, ?D, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_D(time)|acc])
  defp do_strftime(<< ?%, ?d, rest :: bytes >>, time = DateTime[day: day], acc), do: do_strftime(rest, time, [two(day)|acc])
  defp do_strftime(<< ?%, ?e, rest :: bytes >>, time = DateTime[day: day], acc), do: do_strftime(rest, time, [space_two(day)|acc])
  defp do_strftime(<< ?%, ?F, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_F(time)|acc])
  defp do_strftime(<< ?%, ?H, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [two(hour)|acc])
  defp do_strftime(<< ?%, ?h, rest :: bytes >>, time = DateTime[month: month], acc), do: do_strftime(rest, time, [@month_name[month]|acc])
  defp do_strftime(<< ?%, ?I, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [two(hour12(hour))|acc])
  defp do_strftime(<< ?%, ?j, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [three(yday(time))|acc])
  defp do_strftime(<< ?%, ?k, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [space_two(hour)|acc])
  defp do_strftime(<< ?%, ?L, rest :: bytes >>, time = DateTime[nanosec: nanosec], acc), do: do_strftime(rest, time, [three(div(nanosec, 1000000))|acc])
  defp do_strftime(<< ?%, ?l, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [space_two(hour12(hour))|acc])
  defp do_strftime(<< ?%, ?M, rest :: bytes >>, time = DateTime[minute: minute], acc), do: do_strftime(rest, time, [two(minute)|acc])
  defp do_strftime(<< ?%, ?m, rest :: bytes >>, time = DateTime[month: month], acc), do: do_strftime(rest, time, [two(month)|acc])
  defp do_strftime(<< ?%, ?n, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, ["\n"|acc])
  defp do_strftime(<< ?%, ?N, rest :: bytes >>, time = DateTime[nanosec: nanosec], acc), do: do_strftime(rest, time, [build_N(nanosec, 9)|acc])
  defp do_strftime(<< ?%, ?P, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [am_pm_s(hour)|acc])
  defp do_strftime(<< ?%, ?p, rest :: bytes >>, time = DateTime[hour: hour], acc), do: do_strftime(rest, time, [am_pm(hour)|acc])
  defp do_strftime(<< ?%, ?R, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_R(time)|acc])
  defp do_strftime(<< ?%, ?r, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_r(time)|acc])
  defp do_strftime(<< ?%, ?S, rest :: bytes >>, time = DateTime[sec: sec], acc), do: do_strftime(rest, time, [two(sec)|acc])
  defp do_strftime(<< ?%, ?s, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_s(time)|acc])
  defp do_strftime(<< ?%, ?T, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_T(time)|acc])
  defp do_strftime(<< ?%, ?t, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, ["\t"|acc])
  defp do_strftime(<< ?%, ?U, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_U(time)|acc])
  defp do_strftime(<< ?%, ?u, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [wday(time)+1|acc])
  defp do_strftime(<< ?%, ?V, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_V(time)|acc])
  defp do_strftime(<< ?%, ?v, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_v(time)|acc])
  defp do_strftime(<< ?%, ?W, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_W(time)|acc])
  defp do_strftime(<< ?%, ?w, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [wday(time)|acc])
  defp do_strftime(<< ?%, ?X, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_X(time)|acc])
  defp do_strftime(<< ?%, ?x, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [build_x(time)|acc])
  defp do_strftime(<< ?%, ?Y, rest :: bytes >>, time = DateTime[year: year], acc), do: do_strftime(rest, time, [four(year)|acc])
  defp do_strftime(<< ?%, ?y, rest :: bytes >>, time = DateTime[year: year], acc), do: do_strftime(rest, time, [two(year)|acc])
  # time zone
  #defp do_strftime(<< ?%, ?Z, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, ["%"|acc])
  #defp do_strftime(<< ?%, ?z, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, ["%"|acc])
  defp do_strftime(<< other :: utf8, rest :: bytes >>, time = DateTime[], acc), do: do_strftime(rest, time, [<< other :: utf8 >>|acc])
  defp do_strftime(<<>>, DateTime[], acc), do: acc

  defp leap_year_y?(year) do
    rem(year, 4) == 0 && rem(year, 100) != 0 || rem(year, 400) == 0
  end

  defp build_c(time = DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec]) do
    "#{@days_of_week_name_short[wday(time)]} #{@month_name[month]} #{space_two(day)} #{two(hour)}:#{two(minute)}:#{two(sec)} #{four(year)}"
  end

  defp build_D(DateTime[year: year, month: month, day: day]) do
    "#{two(month)}/#{two(day)}/#{two(year)}"
  end

  defp build_F(DateTime[year: year, month: month, day: day]) do
    "#{four(year)}-#{two(month)}-#{two(day)}"
  end

  defp build_N(nanosec, digit) when is_integer(digit) do
    valid_nanosec = nine(nanosec)
    case digit do
      i when i == 0 or 1 == 9 -> valid_nanosec
      i when i > 0 and i < 9 -> take_first(valid_nanosec, digit)
      i when i > 9 -> add_zero(valid_nanosec, digit - 9)
    end
  end

  defp build_R(DateTime[hour: hour, minute: minute]) do
    "#{two(hour)}:#{two(minute)}"
  end

  defp build_r(DateTime[hour: hour, minute: minute, sec: sec]) do
    "#{two(hour12(12))}:#{two(minute)}:#{two(sec)} #{am_pm(hour)}"
  end

  defp build_s(time = DateTime[]) do
    time.new_offset({ 0, 0 }).to_secs - :calendar.datetime_to_gregorian_seconds({{ 1970, 1, 1 }, { 0, 0, 0 }})
  end

  defp build_T(DateTime[hour: hour, minute: minute, sec: sec]) do
    "#{two(hour)}:#{two(minute)}:#{two(sec)}"
  end

  defp build_U(time = DateTime[year: year]) do
    diff = time.yday - first_sunday_yday(year)
    if diff >= 0 do
      two(div(diff, 7) + 1)
    else
      "00"
    end
  end

  defp first_sunday_yday(year) do
    ny_day = DateTime.new(year: year)
    rem(7 - ny_day.wday, 7) + 1
  end

  defp build_W(time = DateTime[year: year]) do
    diff = time.yday - first_monday_yday(year)
    if diff >= 0 do
      two(div(diff, 7) + 1)
    else
      "00"
    end
  end

  defp first_monday_yday(year) do
    ny_day = DateTime.new(year: year)
    rem(8 - ny_day.wday, 7) + 1
  end

  defp build_X(DateTime[hour: hour, minute: minute, sec: sec]) do
    "#{two(hour)}:#{two(minute)}:#{two(sec)}"
  end

  defp build_x(DateTime[year: year, month: month, day: day]) do
    "#{two(month)}/#{two(day)}/#{two(year)}"
  end

  defp build_V(time = DateTime[year: year, month: month, day: day]) do
    wd = time.wday
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
    diff = time.yday - monday_in_first_thursday_week(year)
    two(div(diff, 7) + 1)
  end

  defp monday_in_first_thursday_week(year) do
    ny_day = DateTime.new(year: year)
    rem(11 - ny_day.wday, 7) - 2
  end

  defp build_v(DateTime[year: year, month: month, day: day]) do
    "#{space_two(day)}-#{@month_name_short[month]}-#{four(year)}"
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

  def new_offset(new_o, time = DateTime[offset: offset]) do
    min = round(offset_to_min(new_o) - offset_to_min(offset))
    time = time.plus(minutes: min)
    time.update(offset: new_o)
  end

  defp offset_to_min({ hour, min }) do
    m = abs(hour) * 60 + min
    if hour >= 0, do: m, else: -m
  end
end

defimpl Binary.Inspect, for: DateTime do
  import Kernel, except: [inspect: 2]
  import DateTime.Utils

  def inspect(DateTime[year: year, month: month, day: day, hour: hour, minute: minute, sec: sec, offset: offset], _) do
    ([year, two(month), two(day)] |> Enum.join("-")) <>
    " " <>
    ([two(hour), two(minute), two(sec)] |> Enum.join(":")) <>
    offset_inspect(offset)
  end

  defp offset_inspect({ hour, min }) do
    sign = if hour < 0 , do: "-", else: "+"
    sign <> two(abs(hour)) <> ":" <> two(abs(min))
  end
end
