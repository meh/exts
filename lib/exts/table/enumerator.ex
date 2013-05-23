#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table.Enumerator do
  @opaque t :: record

  defrecordp :enumerator, table: nil, key: nil, reverse: false, safe: true

  def new(table, rest // []) do
    if :ets.first(table.id) == :'$end_of_table' do
      []
    else
      reverse = Keyword.get(rest, :reverse, false)
      safe    = Keyword.get(rest, :safe, true)

      enumerator(table: table, reverse: reverse, safe: safe)
    end
  end

  def table(enumerator(table: table)) do
    table
  end

  def safe?(enumerator(safe: safe)) do
    safe
  end

  def reverse?(enumerator(reverse: reverse)) do
    reverse
  end

  def reverse(enumerator(reverse: reverse) = self) do
    enumerator(self, reverse: !reverse)
  end

  @doc false
  def iterate(enumerator(table: table, reverse: false) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: table.first)
    end

    current = table.read(enumerator(it, :key))
    next    = enumerator(it, key: table.next(enumerator(it, :key)))

    { current, if(enumerator(next, :key), do: next) }
  end

  def iterate(enumerator(table: table, reverse: true) = it) do
    if enumerator(it, :key) == nil do
      it = enumerator(it, key: table.last)
    end

    current = table.read(enumerator(it, :key))
    prev    = enumerator(it, key: table.prev(enumerator(it, :key)))

    { current, if(enumerator(prev, :key), do: prev) }
  end

  def iterate(nil) do
    :stop
  end
end

defimpl Enumerable, for: Exts.Table.Enumerator do
  def reduce(:stop, acc, _) do
    acc
  end

  def reduce({ h, next }, acc, fun) do
    reduce(Exts.Table.Enumerator.iterate(next), fun.(h, acc), fun)
  end

  def reduce(enum, acc, fun) do
    if enum.safe? do
      enum.table.protect

      try do
        reduce(Exts.Table.Enumerator.iterate(enum), acc, fun)
      after
        enum.table.unprotect
      end
    else
      reduce(Exts.Table.Enumerator.iterate(enum), acc, fun)
    end
  end

  def member?(enum, what) do
    enum.table.member?(what)
  end

  def count(self) do
    self.table.size
  end
end
