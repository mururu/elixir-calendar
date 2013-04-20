# DateTime for Elixir

A date and time library for Elixir.
For now this is under development.

## Example

```elixir
iex(1)> time = DateTime.now
2013-04-21 05:36:55+09:00

iex(2)> time.hour
5

iex(3)> time.plus(days: 10, hours: 3)
2013-05-01 08:36:55+09:00

iex(4)> time.strftime("%b %d %Y at %I:%M %p")
"Apr 21 2013 at 05:36 AM"

iex(5)> time.new_offset({-2,30})
2013-04-20 18:06:55-02:30

iex(6)> time1 = DateTime.now
2013-04-21 05:37:28+09:00

iex(7)> time2 = DateTime.now
2013-04-21 05:37:33+09:00

iex(8)> time2.is_after? time1
true
```

## License

MIT
