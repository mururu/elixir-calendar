defrecord DateTime, year: 2000, month: 1, day: 1,
                    hour: 0, minute: 0, second: 0,
                    nanosecond: 0, offset: { 0, 0 }

defmodule Calendar do
  alias :calendar, as: C

  @doc """
  Universal Time
  """
  def universal_time do
    now = :erlang.now

    {{ year, month, day }, { hour, minute, second }} = C.now_to_universal_time(now)
    { _megasecond, _second, microsecond } = now

    DateTime.new [year: year, month: month, day: day,
                  hour: hour, minute: minute, second: second,
                  nanosecond: microsecond * 1000, offset: { 0, 0 }]
  end

  @doc """
  Local Time
  """
  def local_time do
    now = :erlang.now

    {{ year, month, day }, { hour, minute, second }} = C.now_to_local_time(now)
    { _megasecond, _second, microsecond } = now
    offset = calc_offset

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
  String -> DateTime
  """
  def parse(string, formatter) do
    do_parse(string, formatter)
  end

  @doc """
  diff seconds
  """
  def diff(DateTime[] = t1, DateTime[] = t2) do
    seconds1 = t1 |> change_offset({ 0, 0 }) |> to_seconds
    seconds2 = t2 |> change_offset({ 0, 0 }) |> to_seconds
    seconds1 - seconds2
  end

  @doc """
  day of week
  """
  def day_of_week(DateTime[year: year, month: month, day: day]) do
    C.day_of_the_week({ year, month, day }) |> convert_day_of_week
  end

  @doc """
  day of year
  """
  def day_of_year(DateTime[year: year, month: month, day: day]) do
    day +
      if is_leap?(year) do
        leap_year_yday_offset(month)
      else
        common_year_yday_offset(month)
      end
  end

  @doc """
  year
  """
  def year(DateTime[year: year]), do: year

  @doc """
  month
  """
  def month(DateTime[month: month]), do: month

  @doc """
  day
  """
  def day(DateTime[day: day]), do: day

  @doc """
  hour
  """
  def hour(DateTime[hour: hour]), do: hour

  @doc """
  minute
  """
  def minute(DateTime[minute: minute]), do: minute

  @doc """
  second
  """
  def second(DateTime[second: second]), do: second

  @doc """
  leap?
  """
  def is_leap?(DateTime[year: year]) do
    C.is_leap_year(year)
  end

  def is_leap?(year) when is_integer(year) do
    C.is_leap_year(year)
  end

  ## private

  defp calc_offset do
    now = :erlang.now

    local = now |> C.now_to_local_time |> C.datetime_to_gregorian_seconds
    universal = now |> C.now_to_universal_time |> C.datetime_to_gregorian_seconds

    min = div(local , 60) - div(universal, 60)
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
    list = Enum.map(list, &(-&1))
    do_plus(time, list)
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

  defp do_parse(string, formatter) do
    regex = compile_to_regex(formatter)
    list = Regex.named_captures(regex, string) || []
    build_datetime(list)
  end

  defp build_datetime(list) do
    Enum.reduce list, DateTime.new, fn({ key, value }, t) ->
      case build(key, value) do
        { key, value } ->
          apply(DateTime, key, [value, t])
        nil ->
          t
      end
    end
  end

  def build(:YYYY, value) do
    { :year, binary_to_integer(value) }
  end

  def build(:YY, value) do
    { :year, binary_to_integer("20" <> value) }
  end

  def build(:MMMM, value) do
    { :month, month_num(value) }
  end

  def build(:MMM, value) do
    { :month, month_num_s(value) }
  end

  def build(:MM, value) do
    { :month, binary_to_integer(value) }
  end

  def build(:M, value) do
    { :month, binary_to_integer(value) }
  end

  def build(:dd, value) do
    { :day, binary_to_integer(value) }
  end

  def build(:d, value) do
    { :day, binary_to_integer(value) }
  end

  ## TODO
  def build(:EEEE, _value) do
    nil
  end

  def build(:EE, _value) do
    nil
  end

  ## TODO: consider AM or PM
  def build(:hh, value) do
    { :hour, binary_to_integer(value) }
  end

  def build(:h, value) do
    { :hour, binary_to_integer(value) }
  end

  def build(:HH, value) do
    { :hour, binary_to_integer(value) }
  end

  def build(:H, value) do
    { :hour, binary_to_integer(value) }
  end

  ## TODO
  def build(:a, value) do
    nil
  end

  def build(:mm, value) do
    { :minute, binary_to_integer(value) }
  end

  def build(:m, value) do
    { :minute, binary_to_integer(value) }
  end

  def build(:ss, value) do
    { :second, binary_to_integer(value) }
  end

  def build(:s, value) do
    { :second, binary_to_integer(value) }
  end

  def build(:SSS, value) do
    { :nanosecond, binary_to_integer(value <> "000") }
  end

  def build(:SS, value) do
    { :nanosecond, binary_to_integer(value <> "0000") }
  end

  def build(:S, value) do
    { :nanosecond, binary_to_integer(value <> "00000") }
  end

  def build(:ZZ, value) do
    tokens = Regex.named_captures(%r/(?<sign>(\+|-))(?<hour>\d{2}):(?<minute>\d{2})/g, value)
    build_offset(tokens)
  end

  def build(:Z, value) do
    tokens = Regex.named_captures(%r/(?<sign>(\+|-))(?<hour>\d{2})(?<minute>\d{2})/g, value)
    build_offset(tokens)
  end

  defp build_offset(tokens) do
    case tokens[:sign] do
      "+" ->
        { :offset, { binary_to_integer(tokens[:hour]), binary_to_integer(tokens[:minute]) } }
      "-" ->
        { :offset, { -1 * binary_to_integer(tokens[:hour]), binary_to_integer(tokens[:minute]) } }
    end
  end

  defrecordp :format_flg, [:YYYY, :YY, :MMMM, :MMM, :MM, :M, :dd, :d, :EEEE, :EE, :hh, :h, :HH, :H, :a, :mm, :m, :ss, :s, :SSS, :SS, :S, :ZZ, :Z]

  def compile_to_regex(formatter) do
    tokens = compile_to_regex(formatter, [])
    seed = form_regex(tokens, format_flg(), "")
    ("^" <> seed <> "$") |> Regex.compile!("g")
  end

  defp form_regex([:YYYY|t], format_flg(YYYY: true) = flg, s) do
    form_regex(t, flg, "\\d{4}" <> s)
  end

  defp form_regex([:YYYY|t], format_flg(YYYY: _) = flg, s) do
    form_regex(t, format_flg(flg, YYYY: true), "(?<YYYY>\\d{4})" <> s)
  end

  defp form_regex([:YY|t], format_flg(YY: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:YY|t], format_flg(YY: _) = flg, s) do
    form_regex(t, format_flg(flg, YY: true), "(?<YY>\\d{2})" <> s)
  end

  defp form_regex([:MMMM|t], format_flg(MMMM: true) = flg, s) do
    ml = "(January|Feburuary|March|April|May|June|July|August|September|October|November|December)"
    form_regex(t, flg, ml <> s)
  end

  defp form_regex([:MMMM|t], format_flg(MMMM: _) = flg, s) do
    ml = "(January|Feburuary|March|April|May|June|July|August|September|October|November|December)"
    form_regex(t, format_flg(flg, MMMM: true), "(?<MMMM>#{ml})" <> s)
  end

  defp form_regex([:MMM|t], format_flg(MMM: true) = flg, s) do
    ml = "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oc|Nov|Dec)"
    form_regex(t, flg, ml <> s)
  end

  defp form_regex([:MMM|t], format_flg(MMM: _) = flg, s) do
    ml = "(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oc|Nov|Dec)"
    form_regex(t, format_flg(flg, MMM: true), "(?<MMM>#{ml})" <> s)
  end

  defp form_regex([:MM|t], format_flg(MM: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:MM|t], format_flg(MM: _) = flg, s) do
    form_regex(t, format_flg(flg, MM: true), "(?<MM>\\d{2})" <> s)
  end

  defp form_regex([:dd|t], format_flg(dd: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:dd|t], format_flg(dd: _) = flg, s) do
    form_regex(t, format_flg(flg, dd: true), "(?<dd>\\d{2})" <> s)
  end

  defp form_regex([:d|t], format_flg(d: true) = flg, s) do
    form_regex(t, flg, "\\d{1,2}" <> s)
  end

  defp form_regex([:d|t], format_flg(d: _) = flg, s) do
    form_regex(t, format_flg(flg, d: true), "(?<d>\\d{1,2})" <> s)
  end

  defp form_regex([:EEEE|t], format_flg(EEEE: true) = flg, s) do
    wl = "(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)"
    form_regex(t, flg, wl <> s)
  end

  defp form_regex([:EEEE|t], format_flg(EEEE: _) = flg, s) do
    wl = "(Sunday|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday)"
    form_regex(t, format_flg(flg, EEEE: true), "(?<EEEE>#{wl})" <> s)
  end

  defp form_regex([:EE|t], format_flg(EE: true) = flg, s) do
    wl = "(Sun|Mon|Tue|Wed|Thu|Fri|Sat)"
    form_regex(t, flg, wl <> s)
  end

  defp form_regex([:EE|t], format_flg(EE: _) = flg, s) do
    wl = "(Sun|Mon|Tue|Wed|Thu|Fri|Sat)"
    form_regex(t, format_flg(flg, EE: true), "(?<EE>#{wl})" <> s)
  end

  defp form_regex([:hh|t], format_flg(hh: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:hh|t], format_flg(hh: _) = flg, s) do
    form_regex(t, format_flg(flg, hh: true), "(?<hh>\\d{2})" <> s)
  end

  defp form_regex([:h|t], format_flg(h: true) = flg, s) do
    form_regex(t, flg, "\\d{1,2}" <> s)
  end

  defp form_regex([:h|t], format_flg(h: _) = flg, s) do
    form_regex(t, format_flg(flg, h: true), "(?<h>\\d{1,2})" <> s)
  end

  defp form_regex([:HH|t], format_flg(HH: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:HH|t], format_flg(HH: _) = flg, s) do
    form_regex(t, format_flg(flg, HH: true), "(?<HH>\\d{2})" <> s)
  end

  defp form_regex([:H|t], format_flg(H: true) = flg, s) do
    form_regex(t, flg, "\\d{1,2}" <> s)
  end

  defp form_regex([:H|t], format_flg(H: _) = flg, s) do
    form_regex(t, format_flg(flg, H: true), "(?<H>\\d{1,2})" <> s)
  end

  defp form_regex([:a|t], format_flg(a: true) = flg, s) do
    form_regex(t, flg, "(AM|PM)" <> s)
  end

  defp form_regex([:a|t], format_flg(a: _) = flg, s) do
    form_regex(t, format_flg(flg, a: true), "(?<a>(AM|PM))" <> s)
  end

  defp form_regex([:mm|t], format_flg(mm: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:mm|t], format_flg(mm: _) = flg, s) do
    form_regex(t, format_flg(flg, mm: true), "(?<mm>\\d{2})" <> s)
  end

  defp form_regex([:m|t], format_flg(m: true) = flg, s) do
    form_regex(t, flg, "\\d{1,2}" <> s)
  end

  defp form_regex([:m|t], format_flg(m: _) = flg, s) do
    form_regex(t, format_flg(flg, m: true), "(?<m>\\d{1,2})" <> s)
  end

  defp form_regex([:ss|t], format_flg(ss: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:ss|t], format_flg(ss: _) = flg, s) do
    form_regex(t, format_flg(flg, ss: true), "(?<ss>\\d{2})" <> s)
  end

  defp form_regex([:s|t], format_flg(s: true) = flg, s) do
    form_regex(t, flg, "\\d{1,2}" <> s)
  end

  defp form_regex([:s|t], format_flg(s: _) = flg, s) do
    form_regex(t, format_flg(flg, s: true), "(?<s>\\d{1,2})" <> s)
  end

  defp form_regex([:SSS|t], format_flg(SSS: true) = flg, s) do
    form_regex(t, flg, "\\d{3}" <> s)
  end

  defp form_regex([:SSS|t], format_flg(SSS: _) = flg, s) do
    form_regex(t, format_flg(flg, SSS: true), "(?<SSS>\\d{3})" <> s)
  end

  defp form_regex([:SS|t], format_flg(SS: true) = flg, s) do
    form_regex(t, flg, "\\d{2}" <> s)
  end

  defp form_regex([:SS|t], format_flg(SS: _) = flg, s) do
    form_regex(t, format_flg(flg, SS: true), "(?<SS>\\d{2})" <> s)
  end

  defp form_regex([:S|t], format_flg(S: true) = flg, s) do
    form_regex(t, flg, "\\d{1}" <> s)
  end

  defp form_regex([:S|t], format_flg(S: _) = flg, s) do
    form_regex(t, format_flg(flg, S: true), "(?<S>\\d{1})" <> s)
  end

  defp form_regex([:ZZ|t], format_flg(ZZ: true) = flg, s) do
    form_regex(t, flg, "[+-]\\d{2}:\\d{2}" <> s)
  end

  defp form_regex([:ZZ|t], format_flg(ZZ: _) = flg, s) do
    form_regex(t, format_flg(flg, ZZ: true), "(?<ZZ>[+-]\\d{2}:\\d{2})" <> s)
  end

  defp form_regex([:Z|t], format_flg(Z: true) = flg, s) do
    form_regex(t, flg, "[+-]\\d{4}" <> s)
  end

  defp form_regex([:Z|t], format_flg(Z: _) = flg, s) do
    form_regex(t, format_flg(flg, Z: true), "(?<Z>[+-]\\d{4})" <> s)
  end

  defp form_regex([bin|t], format_flg() = flg, s) when is_binary(bin) do
    form_regex(t, flg, bin <> s)
  end

  defp form_regex([], format_flg() = _flg, s) do
    s
  end

  defp compile_to_regex("YYYY" <> rest, list) do
    compile_to_regex(rest, [:YYYY|list])
  end

  defp compile_to_regex("YY" <> rest, list) do
    compile_to_regex(rest, [:YY|list])
  end

  defp compile_to_regex("MMMM" <> rest, list) do
    compile_to_regex(rest, [:MMMM|list])
  end

  defp compile_to_regex("MMM" <> rest, list) do
    compile_to_regex(rest, [:MMM|list])
  end

  defp compile_to_regex("MM" <> rest, list) do
    compile_to_regex(rest, [:MM|list])
  end

  defp compile_to_regex("M" <> rest, list) do
    compile_to_regex(rest, [:M|list])
  end

  defp compile_to_regex("dd" <> rest, list) do
    compile_to_regex(rest, [:dd|list])
  end

  defp compile_to_regex("d" <> rest, list) do
    compile_to_regex(rest, [:d|list])
  end

  defp compile_to_regex("EEEE" <> rest, list) do
    compile_to_regex(rest, [:EEEE|list])
  end

  defp compile_to_regex("EE" <> rest, list) do
    compile_to_regex(rest, [:EE|list])
  end

  defp compile_to_regex("hh" <> rest, list) do
    compile_to_regex(rest, [:hh|list])
  end

  defp compile_to_regex("h" <> rest, list) do
    compile_to_regex(rest, [:h|list])
  end

  defp compile_to_regex("HH" <> rest, list) do
    compile_to_regex(rest, [:HH|list])
  end

  defp compile_to_regex("H" <> rest, list) do
    compile_to_regex(rest, [:H|list])
  end

  defp compile_to_regex("a" <> rest, list) do
    compile_to_regex(rest, [:a|list])
  end

  defp compile_to_regex("mm" <> rest, list) do
    compile_to_regex(rest, [:mm|list])
  end

  defp compile_to_regex("m" <> rest, list) do
    compile_to_regex(rest, [:m|list])
  end

  defp compile_to_regex("ss" <> rest, list) do
    compile_to_regex(rest, [:ss|list])
  end

  defp compile_to_regex("s" <> rest, list) do
    compile_to_regex(rest, [:s|list])
  end

  defp compile_to_regex("SSS" <> rest, list) do
    compile_to_regex(rest, [:SSS|list])
  end

  defp compile_to_regex("SS" <> rest, list) do
    compile_to_regex(rest, [:SS|list])
  end

  defp compile_to_regex("S" <> rest, list) do
    compile_to_regex(rest, [:S|list])
  end

  defp compile_to_regex("ZZ" <> rest, list) do
    compile_to_regex(rest, [:ZZ|list])
  end

  defp compile_to_regex("Z" <> rest, list) do
    compile_to_regex(rest, [:Z|list])
  end

  defp compile_to_regex("''" <> rest, list) do
    compile_to_regex(rest, ["'"|list])
  end

  defp compile_to_regex("'" <> rest, list) do
    compile_to_regex_escape(rest, list)
  end

  defp compile_to_regex(<< h, rest :: binary >>, list) when not (h in ?a..?z or h in ?A..?Z) do
    compile_to_regex(rest, [<< h >>|list])
  end

  defp compile_to_regex(<<>>, list) do
    list
  end

  defp compile_to_regex_escape("'" <> rest, list) do
    compile_to_regex(rest, list)
  end

  defp compile_to_regex_escape(<< h, rest :: binary >>, list) do
    compile_to_regex_escape(rest, [<< h >>|list])
  end

  defp compile_to_regex_escape(<<>>, list) do
    list
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

  defp month_num("January"),   do: 1
  defp month_num("Feburuary"), do: 2
  defp month_num("March"),     do: 3
  defp month_num("April"),     do: 4
  defp month_num("May"),       do: 5
  defp month_num("June"),      do: 6
  defp month_num("July"),      do: 7
  defp month_num("August"),    do: 8
  defp month_num("September"), do: 9
  defp month_num("October"),   do: 10
  defp month_num("November"),  do: 11
  defp month_num("December"),  do: 12

  defp month_num_s("Jan"), do: 1
  defp month_num_s("Feb"), do: 2
  defp month_num_s("Mar"), do: 3
  defp month_num_s("Apr"), do: 4
  defp month_num_s("May"), do: 5
  defp month_num_s("Jun"), do: 6
  defp month_num_s("Jul"), do: 7
  defp month_num_s("Aug"), do: 8
  defp month_num_s("Sep"), do: 9
  defp month_num_s("Oct"), do: 10
  defp month_num_s("Nov"), do: 11
  defp month_num_s("Dec"), do: 12

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

defimpl Inspect, for: DateTime do
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
