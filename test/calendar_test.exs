Code.require_file "test_helper.exs", __DIR__

defmodule CalendarTest do
  use ExUnit.Case, async: true

  test :from_tuple do
    t = Calendar.from_tuple({{ 2000, 1, 2 }, { 3, 4, 5 }})
    assert t.year == 2000
    assert t.month == 1
    assert t.day == 2
    assert t.hour == 3
    assert t.minute == 4
    assert t.second == 5
  end

  test :to_tuple do
    t = DateTime.new(year: 2000, month: 1, day: 2, hour: 3, minute: 4, second: 5)
    assert Calendar.to_tuple(t) == {{ 2000, 1, 2 }, { 3, 4, 5 }}
  end

  test :from_unix_time do
    t = Calendar.from_unix_time(946782245)
    assert t.year == 2000
    assert t.month == 1
    assert t.day == 2
    assert t.hour == 3
    assert t.minute == 4
    assert t.second == 5
  end

  test :to_unix_time do
    t = DateTime.new(year: 2000, month: 1, day: 2, hour: 3, minute: 4, second: 5)
    assert Calendar.to_unix_time(t) == 946782245
  end

  test :valid? do
    t = DateTime.new(year: 2001, month: 2, day: 28, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    assert Calendar.valid?(t)

    t = DateTime.new(year: 2001, month: 2, day: 29, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    refute Calendar.valid?(t)
  end

  test :universal_time do
    t = Calendar.universal_time
    assert Calendar.valid?(t)
  end

  test :local_time do
    t = Calendar.local_time
    assert Calendar.valid?(t)
  end

  test :plus do
    t = DateTime.new(year: 2000, month: 2, day: 28, hour: 23, minute: 0, second: 0, nanosecond: 1, offset: { 1, 1 })
    t = Calendar.plus(t, days: 1, hours: 1, minutes: 1, seconds: 1)
    assert t.year == 2000
    assert t.month == 3
    assert t.day == 1
    assert t.hour == 0
    assert t.minute == 1
    assert t.second == 1
    assert t.nanosecond == 1
    assert t.offset == { 1, 1 }
  end

  test :minus do
    t = DateTime.new(year: 2000, month: 3, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 1, offset: { 1, 1 })
    t = Calendar.minus(t, days: 1, hours: 1, minutes: 1, seconds: 1)
    assert t.year == 2000
    assert t.month == 2
    assert t.day == 28
    assert t.hour == 22
    assert t.minute == 58
    assert t.second == 59
    assert t.nanosecond == 1
    assert t.offset == { 1, 1 }
  end

  test :change_offset do
    t = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t = Calendar.change_offset(t, { -3, 30 })
    assert t.year == 1999
    assert t.month == 12
    assert t.day == 31
    assert t.hour == 20
    assert t.minute == 30
    assert t.second == 0
    assert t.nanosecond == 0
    assert t.offset == { -3, 30 }
  end

  test :equal? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    Calendar.equal?(t1, t2)
  end

  test :is_after? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, second: 0, nanosecond: 0, offset: { 0, 0 })
    refute Calendar.is_after?(t1, t2)
    assert Calendar.is_after?(t2, t1)

    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, second: 0, nanosecond: 0, offset: { 1, 0 })
    assert Calendar.is_after?(t1, t2)
    refute Calendar.is_after?(t2, t1)
  end

  test :is_before? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, second: 0, nanosecond: 0, offset: { 0, 0 })
    assert Calendar.is_before?(t1, t2)
    refute Calendar.is_before?(t2, t1)

    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, second: 0, nanosecond: 0, offset: { 1, 0 })
    refute Calendar.is_before?(t1, t2)
    assert Calendar.is_before?(t2, t1)
  end

  test :diff do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, second: 0)
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 30)
    assert Calendar.diff(t1, t2) == 30
  end

  test :day_of_week do
    t = DateTime.new(year: 2013, month: 6, day: 8)
    assert Calendar.day_of_week(t) == 6

    t = DateTime.new(year: 2013, month: 6, day: 9)
    assert Calendar.day_of_week(t) == 0
  end

  test :day_of_year do
    t = DateTime.new(year: 2013, month: 1, day: 1)
    assert Calendar.day_of_year(t) == 1

    t = DateTime.new(year: 2013, month: 6, day: 11)
    assert Calendar.day_of_year(t) == 162
  end

  test :year do
    t = DateTime.new(year: 2013)
    assert Calendar.year(t) == 2013
  end

  test :month do
    t = DateTime.new(month: 1)
    assert Calendar.month(t) == 1
  end

  test :day do
    t = DateTime.new(day: 2)
    assert Calendar.day(t) == 2
  end

  test :hour do
    t = DateTime.new(hour: 3)
    assert Calendar.hour(t) == 3
  end

  test :minute do
    t = DateTime.new(minute: 4)
    assert Calendar.minute(t) == 4
  end

  test :second do
    t = DateTime.new(second: 5)
    assert Calendar.second(t) == 5
  end

  test :is_leap? do
    t1 = DateTime.new(year: 2000)
    t2 = DateTime.new(year: 2100)
    assert Calendar.is_leap?(t1)
    refute Calendar.is_leap?(t2)

    assert Calendar.is_leap?(2000)
    refute Calendar.is_leap?(2100)
  end
end

defmodule Calendar.FormatTest do
  use ExUnit.Case, async: true

  test "YYYY" do
    t = DateTime.new(year: 2013)
    assert Calendar.format(t, "YYYY") == "2013"
  end

  test "YY" do
    t = DateTime.new(year: 2013)
    assert Calendar.format(t, "YY") == "13"
  end

  test "MMMM" do
    t = DateTime.new(month: 6)
    assert Calendar.format(t, "MMMM") == "June"
  end

  test "MMM" do
    t = DateTime.new(month: 6)
    assert Calendar.format(t, "MMM") == "Jun"
  end

  test "MM" do
    t = DateTime.new(month: 6)
    assert Calendar.format(t, "MM") == "06"

    t = DateTime.new(month: 10)
    assert Calendar.format(t, "MM") == "10"
  end

  test "M" do
    t = DateTime.new(month: 6)
    assert Calendar.format(t, "M") == "6"

    t = DateTime.new(month: 10)
    assert Calendar.format(t, "M") == "10"
  end

  test "dd" do
    t = DateTime.new(day: 9)
    assert Calendar.format(t, "dd") == "09"

    t = DateTime.new(day: 15)
    assert Calendar.format(t, "dd") == "15"
  end

  test "d" do
    t = DateTime.new(day: 9)
    assert Calendar.format(t, "d") == "9"

    t = DateTime.new(day: 15)
    assert Calendar.format(t, "d") == "15"
  end

  test "EEEE" do
    t = DateTime.new(year: 2013, month: 6, day: 9)
    assert Calendar.format(t, "EEEE") == "Sunday"
  end

  test "EE" do
    t = DateTime.new(year: 2013, month: 6, day: 9)
    assert Calendar.format(t, "EE") == "Sun"
  end

  test "hh" do
    t = DateTime.new(hour: 3)
    assert Calendar.format(t, "hh") == "03"

    t = DateTime.new(hour: 11)
    assert Calendar.format(t, "hh") == "11"

    t = DateTime.new(hour: 15)
    assert Calendar.format(t, "hh") == "03"

    t = DateTime.new(hour: 23)
    assert Calendar.format(t, "hh") == "11"
  end

  test "h" do
    t = DateTime.new(hour: 3)
    assert Calendar.format(t, "h") == "3"

    t = DateTime.new(hour: 11)
    assert Calendar.format(t, "h") == "11"

    t = DateTime.new(hour: 15)
    assert Calendar.format(t, "h") == "3"

    t = DateTime.new(hour: 23)
    assert Calendar.format(t, "h") == "11"
  end

  test "HH" do
    t = DateTime.new(hour: 3)
    assert Calendar.format(t, "HH") == "03"

    t = DateTime.new(hour: 23)
    assert Calendar.format(t, "HH") == "23"
  end

  test "H" do
    t = DateTime.new(hour: 3)
    assert Calendar.format(t, "H") == "3"

    t = DateTime.new(hour: 23)
    assert Calendar.format(t, "H") == "23"
  end

  test "a" do
    t = DateTime.new(hour: 11)
    assert Calendar.format(t, "a") == "AM"

    t = DateTime.new(hour: 12)
    assert Calendar.format(t, "a") == "PM"
  end

  test "mm" do
    t = DateTime.new(minute: 3)
    assert Calendar.format(t, "mm") == "03"

    t = DateTime.new(minute: 33)
    assert Calendar.format(t, "mm") == "33"
  end

  test "m" do
    t = DateTime.new(minute: 3)
    assert Calendar.format(t, "m") == "3"

    t = DateTime.new(minute: 33)
    assert Calendar.format(t, "m") == "33"
  end

  test "ss" do
    t = DateTime.new(second: 3)
    assert Calendar.format(t, "ss") == "03"

    t = DateTime.new(second: 33)
    assert Calendar.format(t, "ss") == "33"
  end

  test "s" do
    t = DateTime.new(second: 3)
    assert Calendar.format(t, "s") == "3"

    t = DateTime.new(second: 33)
    assert Calendar.format(t, "s") == "33"
  end

  test "SSS" do
    t = DateTime.new(nanosecond: 123000)
    assert Calendar.format(t, "SSS") == "123"

    t = DateTime.new(nanosecond: 12300)
    assert Calendar.format(t, "SSS") == "012"

    t = DateTime.new(nanosecond: 1230)
    assert Calendar.format(t, "SSS") == "001"
  end

  test "SS" do
    t = DateTime.new(nanosecond: 123000)
    assert Calendar.format(t, "SS") == "12"

    t = DateTime.new(nanosecond: 12300)
    assert Calendar.format(t, "SS") == "01"

    t = DateTime.new(nanosecond: 1230)
    assert Calendar.format(t, "SS") == "00"
  end

  test "S" do
    t = DateTime.new(nanosecond: 123000)
    assert Calendar.format(t, "S") == "1"

    t = DateTime.new(nanosecond: 12300)
    assert Calendar.format(t, "S") == "0"
  end

  test "ZZ" do
    t = DateTime.new(offset: { 0, 0 })
    assert Calendar.format(t, "ZZ") == "+00:00"

    t = DateTime.new(offset: { -11, 30 })
    assert Calendar.format(t, "ZZ") == "-11:30"
  end

  test "Z" do
    t = DateTime.new(offset: { 0, 0 })
    assert Calendar.format(t, "Z") == "+0000"

    t = DateTime.new(offset: { -11, 30 })
    assert Calendar.format(t, "Z") == "-1130"
  end

  test "escape" do
    t = DateTime.new
    assert Calendar.format(t, "'a'") == "a"
    assert Calendar.format(t, "'a") == "a"
    assert Calendar.format(t, "'''") == "'"
    assert Calendar.format(t, "'a''a'a'a'") == "aaAMa"
  end

  test "rfc" do
    t = DateTime.new(year: 2013, month: 3, day: 1, hour: 20, minute: 3, second: 15, offset: { -3, 30 })
    assert Calendar.format(t, "EE, dd MMM YYYY HH:mm:ss Z") == "Fri, 01 Mar 2013 20:03:15 -0330"
  end

  test "utf8" do
    t = DateTime.new(year: 2013)
    assert Calendar.format(t, "YYあYY'い'") == "13あ13い"
  end
end

defmodule Calendar.ParseTest do
  use ExUnit.Case, async: true

  test "YYYY" do
    t = Calendar.parse("2013", "YYYY")
    assert t.year == 2013
  end

  test "YY" do
    t = Calendar.parse("13", "YY")
    assert t.year == 2013
  end

  test "MMMM" do
    t = Calendar.parse("Feburuary", "MMMM")
    assert t.month == 2
  end

  test "MMM" do
    t = Calendar.parse("Feb", "MMM")
    assert t.month == 2
  end

  test "MM" do
    t = Calendar.parse("03", "MM")
    assert t.month == 3
  end

  test "M" do
    #t = Calendar.parse("3", "M")
    #assert t.month == 3

    #t = Calendar.parse("11", "M")
    #assert t.month == 11
  end

  test "dd" do
    t = Calendar.parse("03", "d")
    assert t.day == 3
  end

  test "d" do
    t = Calendar.parse("3", "d")
    assert t.day == 3

    t = Calendar.parse("11", "d")
    assert t.day == 11
  end

  test "EEEE" do
    Calendar.parse("Friday", "EEEE")
  end

  test "EE" do
    Calendar.parse("Fri", "EE")
  end

  test "hh" do
    t = Calendar.parse("03", "hh")
    assert t.hour == 3
  end

  test "h" do
    t = Calendar.parse("3", "h")
    assert t.hour == 3

    t = Calendar.parse("11", "h")
    assert t.hour == 11
  end

  test "HH" do
    t = Calendar.parse("03", "HH")
    assert t.hour == 3
  end

  test "H" do
    t = Calendar.parse("3", "H")
    assert t.hour == 3

    t = Calendar.parse("11", "H")
    assert t.hour == 11
  end

  test "a" do
    t = Calendar.parse("AM1", "ah")
    assert t.hour == 1

    #t = Calendar.parse("PM1", "ah")
    #assert t.hour == 13

    ## this should raise?
    t = Calendar.parse("PM1", "aH")
    assert t.hour == 1

    #t = Calendar.parse("PM", "a")
    #assert t.hour == 12
  end

  test "mm" do
    t = Calendar.parse("03", "mm")
    assert t.minute == 3
  end

  test "m" do
    t = Calendar.parse("3", "m")
    assert t.minute == 3

    t = Calendar.parse("11", "m")
    assert t.minute == 11
  end

  test "ss" do
    t = Calendar.parse("03", "ss")
    assert t.second == 3
  end

  test "s" do
    t = Calendar.parse("3", "s")
    assert t.second == 3

    t = Calendar.parse("11", "s")
    assert t.second == 11
  end

  test "SSS" do
    t = Calendar.parse("123", "SSS")
    assert t.nanosecond == 123000
  end

  test "SS" do
    t = Calendar.parse("12", "SS")
    assert t.nanosecond == 120000
  end

  test "S" do
    t = Calendar.parse("1", "S")
    assert t.nanosecond == 100000
  end

  test "ZZ" do
    t = Calendar.parse("-12:30", "ZZ")
    assert t.offset == { -12, 30 }
  end

  test "Z" do
    t = Calendar.parse("+0315", "Z")
    assert t.offset == { 3, 15 }
  end

  test "escape" do
    t = Calendar.parse("aa12a", "'a''a'd'a'")
    assert t.day == 12
  end

  test "ambiguity" do
    t = Calendar.parse("111", "dh")
    assert t.day == 11
    assert t.hour == 1

    t = Calendar.parse("111", "dhh")
    assert t.day == 1
    assert t.hour == 11
  end

  test "rfc" do
    t1 = DateTime.new(year: 2013, month: 3, day: 1, hour: 20, minute: 3, second: 15, offset: { -3, 30 })
    t2 = Calendar.parse("Fri, 01 Mar 2013 20:03:15 -0330", "EE, dd MMM YYYY HH:mm:ss Z")
    assert Calendar.equal?(t1, t2)
  end

  test "utf8" do
    t = Calendar.parse("11あ12い", "YYあYY'い'")
    assert t.year == 2012
  end
end
