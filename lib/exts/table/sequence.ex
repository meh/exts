#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table.Sequence do
  @opaque t :: record

  defrecordp :sequence, table: nil, key: nil, reverse: false, safe: true

  def new(table, rest // []) do
    if :ets.first(table.id) == :'$end_of_table' do
      nil
    else
      reverse = Keyword.get(rest, :reverse, false)
      safe    = Keyword.get(rest, :safe, true)

      sequence(table: table, reverse: reverse, safe: safe)
    end
  end

  def table(sequence(table: table)) do
    table
  end

  def safe?(sequence(safe: safe)) do
    safe
  end

  def reverse?(sequence(reverse: reverse)) do
    reverse
  end

  def reverse(sequence(reverse: reverse) = self) do
    sequence(self, reverse: !reverse)
  end

  def first(sequence(table: table, reverse: false, key: key) = it) do
    if key == nil do
      table.read(table.first)
    else
      table.read(key)
    end
  end

  def first(sequence(table: table, reverse: true, key: key) = it) do
    if key == nil do
      table.read(table.last)
    else
      table.read(key)
    end
  end

  def next(sequence(table: table, reverse: false, key: key) = it) do
    if key == nil do
      sequence(it, key: table.next(table.first))
    else
      case table.next(key) do
        nil ->
          nil

        key ->
          sequence(it, key: key)
      end
    end
  end

  def next(sequence(table: table, reverse: true, key: key) = it) do
    if key == nil do
      sequence(it, key: table.prev(table.last))
    else
      case table.prev(key) do
        nil ->
          nil

        key ->
          sequence(it, key: key)
      end
    end
  end
end

defimpl Data.Reversible, for: Exts.Table.Sequence do
  defdelegate reverse(self), to: Exts.Table.Sequence
end

defimpl Data.Sequence, for: Exts.Table.Sequence do
  defdelegate first(self), to: Exts.Table.Sequence
  defdelegate next(self), to: Exts.Table.Sequence
end

defimpl Enumerable, for: Exts.Table.Sequence do
  def reduce(self, acc, fun) do
    Data.Seq.reduce(self, acc, fun)
  end

  def member?(enum, what) do
    enum.table.member?(what)
  end

  def count(self) do
    self.table.size
  end
end
