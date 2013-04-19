#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table.Iterator do
  @opaque t :: record

  defrecordp :iterator, table: nil, safe: true, reverse: false

  def new(table, rest) do
    if :ets.first(table.id) == :'$end_of_table' do
      []
    else
      iterator(table: table, reverse: rest[:reverse])
    end
  end

  def safe?(iterator(safe: safe)) do
    safe
  end

  def reverse?(iterator(reverse: reverse)) do
    reverse
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
