#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table.Iterator do
  @opaque t :: record

  defrecordp :iterator, table: nil, key: nil, reverse: false

  def new(table, rest) do
    if :ets.first(table.id) == :'$end_of_table' do
      []
    else
      reverse = Keyword.get(rest, :reverse, false)

      iterator(table: table, reverse: reverse)
    end
  end

  def table(iterator(table: table)) do
    table
  end

  def reverse?(iterator(reverse: reverse)) do
    reverse
  end

  @doc false
  def iterate(iterator(table: table, reverse: false) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: table.first)
    end

    current = table.read(iterator(it, :key))
    next    = iterator(it, key: table.next(iterator(it, :key)))

    { current, if(iterator(next, :key), do: next) }
  end

  def iterate(iterator(table: table, reverse: true) = it) do
    if iterator(it, :key) == nil do
      it = iterator(it, key: table.last)
    end

    current = table.read(iterator(it, :key))
    prev    = iterator(it, key: table.prev(iterator(it, :key)))

    { current, if(iterator(prev, :key), do: prev) }
  end

  def iterate(nil) do
    :stop
  end
end

defimpl Enum.Iterator, for: Exts.Table.Iterator do
  def iterator(self) do
    { Exts.Table.Iterator.iterate(&1), Exts.Table.Iterator.iterate(self) }
  end

  def count(self) do
    self.table.size
  end
end
