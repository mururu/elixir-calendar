# DateTime Library for Elixir

A date and time library for Elixir.
WIP

## Example

```elixir
iex(1)> time = Calendar.local_time
2013-07-10 02:49:11+09:00

iex(2)> time.hour
2

iex(3)> Calendar.plus(time, days: 10, hours: 3)
2013-07-20 05:49:45+09:00

iex(4)> Calendar.format(time, "EE, dd MMM YYYY HH:mm:ss Z")
"Wed, 10 Jul 2013 02:49:45 +0900"

iex(5)> Calendar.change_offset(time, {-2,30})
2013-07-09 15:19:45-02:30

iex(6)> time1 = Calendar.local_time
2013-07-10 02:52:07+09:00

iex(7)> time2 = Calendar.local_time
2013-07-10 02:52:15+09:00

iex(8)> Calendar.is_before?(time1, time2)
true

iex(9)> Calendar.parse("Fri, 01 Mar 2013 20:03:15 -0330", "EE, dd MMM YYYY HH:mm:ss Z")
2013-03-01 20:03:15-03:30
```

## License

MIT
