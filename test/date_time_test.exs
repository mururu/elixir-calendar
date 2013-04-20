Code.require_file "../test_helper.exs", __FILE__

defmodule DateTimeTest do
  use ExUnit.Case, async: true

  test :accessor do
    t = DateTime.new
    assert t.year == 1970
    assert t.month == 1
    assert t.day == 1
    assert t.hour == 0
    assert t.minute == 0
    assert t.sec == 0
    assert t.nanosec == 0
    assert t.offset == { 0, 0 }
  end

  test :valid? do
    t = DateTime.new(year: 2001, month: 2, day: 28, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    assert t.valid?

    t = DateTime.new(year: 2001, month: 2, day: 29, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    refute t.valid?
  end

  test :plus do
    t = DateTime.new(year: 2000, month: 2, day: 28, hour: 23, minute: 0, sec: 0, nanosec: 1, offset: { 1, 1 })
    t = t.plus(days: 1, hours: 1, minutes: 1, secs: 1)
    assert t.year == 2000
    assert t.month == 3
    assert t.day == 1
    assert t.hour == 0
    assert t.minute == 1
    assert t.sec == 1
    assert t.nanosec == 1
    assert t.offset == { 1, 1 }
  end

  test :minus do
    t = DateTime.new(year: 2000, month: 3, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 1, offset: { 1, 1 })
    t = t.minus(days: 1, hours: 1, minutes: 1, secs: 1)
    assert t.year == 2000
    assert t.month == 2
    assert t.day == 28
    assert t.hour == 22
    assert t.minute == 58
    assert t.sec == 59
    assert t.nanosec == 1
    assert t.offset == { 1, 1 }
  end

  test :new_offset do
    t = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t = t.new_offset({ -3, 30 })
    assert t.year == 1999
    assert t.month == 12
    assert t.day == 31
    assert t.hour == 20
    assert t.minute == 30
    assert t.sec == 0
    assert t.nanosec == 0
    assert t.offset == { -3, 30 }
  end

  test :equal? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t1.equal? t2
  end

  test :is_after? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, sec: 0, nanosec: 0, offset: { 0, 0 })
    refute t1.is_after? t2
    assert t2.is_after? t1

    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, sec: 0, nanosec: 0, offset: { 1, 0 })
    assert t1.is_after? t2
    refute t2.is_after? t1
  end

  test :is_before? do
    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, sec: 0, nanosec: 0, offset: { 0, 0 })
    assert t1.is_before? t2
    refute t2.is_before? t1

    t1 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 0, sec: 0, nanosec: 0, offset: { 0, 0 })
    t2 = DateTime.new(year: 2000, month: 1, day: 1, hour: 0, minute: 1, sec: 0, nanosec: 0, offset: { 1, 0 })
    refute t1.is_before? t2
    assert t2.is_before? t1
  end
end
