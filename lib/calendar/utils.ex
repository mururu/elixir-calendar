defmodule Calendar.Utils do
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
