Code.require_file "../test_helper.exs", __FILE__

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

  test :new_offset do
    t = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, second: 0, nanosecond: 0, offset: { 0, 0 })
    t = Calendar.new_offset(t, { -3, 30 })
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
end
