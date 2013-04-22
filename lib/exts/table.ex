#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table do
  @opaque t :: { Exts.Table, Exts.table, :bag | :duplicate_bag | :set | :oredered_set }

  defrecordp :table, id: nil, type: nil

  @spec new :: t
  def new do
    new([])
  end

  @spec new(integer | atom | Keyword.t) :: t
  def new(options) when is_list options do
    table(id: Exts.new(options), type: options[:type] || :set)
  end

  def new(id) do
    table(id: id, type: :ets.info(id, :type))
  end

  def id(table(id: id)) do
    id
  end

  @spec rename(atom, t) :: atom
  def rename(name, table(id: id)) do
    Exts.rename(id, name)
  end

  @spec give_to(pid, t) :: true
  @spec give_to(pid, any, t) :: true
  def give_to(pid, data // nil, table(id: id)) do
    Exts.give_to(id, pid, data)
  end

  @spec load(String.t)            :: { :ok, t } | { :error, any }
  @spec load(String.t, Keyword.t) :: { :ok, t } | { :error, any }
  def load(path, options // []) do
    case :ets.file2tab(path, options) do
      { :ok, id }        -> { :ok, new(id) }
      { :error, reason } -> { :error, reason }
    end
  end

  @spec dump(String.t, t) :: :ok | { :error, any }
  def dump(path, table(id: id)) do
    :ets.tab2file(id, path)
  end

  @spec dump(String.t, Keyword.t, t) :: :ok | { :error, any }
  def dump(path, options, table(id: id)) do
    :ets.tab2file(id, path, options)
  end

  def protect(table(id: id)) do
    Exts.protect(id)
  end

  def unprotect(table(id: id)) do
    Exts.unprotect(id)
  end

  @spec bag?(t) :: boolean
  def bag?(table(type: type)) do
    type == :bag
  end

  @spec duplicate_bag?(t) :: boolean
  def duplicate_bag?(table(type: type)) do
    type == :duplicate_bag
  end

  @spec set?(t) :: boolean
  def set?(table(type: type)) do
    type == :set
  end

  @spec ordered_set?(t) :: boolean
  def ordered_set?(table(type: type)) do
    type == :ordered_set
  end

  @spec info(t, atom) :: any | nil
  def info(key, table(id: id)) do
    Exts.info(id, key)
  end

  @spec size(t) :: integer
  def size(table(id: id)) do
    Exts.info(id, :size)
  end

  @spec to_list(t) :: [record]
  def to_list(table(id: id)) do
    Exts.to_list(id)
  end

  @spec clear(t) :: true
  def clear(table(id: id)) do
    Exts.clear(id)
  end

  @spec destroy(t) :: true
  def destroy(table(id: id)) do
    Exts.destroy(id)
  end

  @spec contains?(any, t) :: boolean
  def contains?(key, table(id: id)) do
    case Exts.read(id, key) do
      [] -> false
      _  -> true
    end
  end

  @spec read(any, t) :: [record] | record
  def read(key, table(id: id, type: type)) when type in [:bag, :duplicate_bag] do
    case Exts.read(id, key) do
      [] -> nil
      r  -> r
    end
  end

  def read(key, table(id: id, type: type)) when type in [:set, :ordered_set] do
    Enum.first Exts.read(id, key)
  end

  @spec at(integer, t) :: [record]
  def at(slot, table(id: id)) do
    Exts.at(id, slot)
  end

  @spec first(t) :: any
  def first(table(id: id)) do
    Exts.first(id)
  end

  @spec next(any, t) :: any
  def next(key, table(id: id)) do
    Exts.next(id, key)
  end

  @spec prev(any, t) :: any
  def prev(key, table(id: id)) do
    Exts.prev(id, key)
  end

  @spec last(t) :: any
  def last(table(id: id)) do
    Exts.last(id)
  end

  @spec select(any, t) :: [any]
  def select(match_spec, table(id: id)) do
    Exts.select(id, match_spec)
  end

  @spec select(integer, any, t) :: [any]
  def select(limit, match_spec, table(id: id)) do
    Exts.select(limit, id, match_spec)
  end

  @spec reverse_select(any, t) :: [any]
  def reverse_select(match_spec, table(id: id)) do
    Exts.reverse_select(id, match_spec)
  end

  @spec reverse_select(integer, any, t) :: [any]
  def reverse_select(limit, match_spec, table(id: id)) do
    Exts.reverse_select(limit, id, match_spec)
  end

  @spec match(any, t) :: Match.t | nil
  def match(pattern, table(id: id)) do
    Exts.match(id, pattern)
  end

  @spec match(any | integer, Keyword.t | any, t) :: Match.t | nil
  def match(limit_or_pattern, options_or_pattern, table(id: id)) do
    Exts.match(id, limit_or_pattern, options_or_pattern)
  end

  @spec match(integer, any, Keyword.t, t) :: Match.t | nil
  def match(limit, pattern, options, table(id: id)) do
    Exts.match(id, limmit patterb, options)
  end

  def count(table(id: id)) do
    Exts.count(id)
  end

  def count(spec, table(id: id)) do
    Exts.count(id, spec)
  end

  @spec foldl(any, (record, any -> any), t) :: any
  def foldl(acc, fun, table(id: id)) do
    Exts.foldl(id, acc, fun)
  end

  @spec foldr(any, (record, any -> any), t) :: any
  def foldr(acc, fun, table(id: id)) do
    Exts.foldr(id, acc, fun)
  end

  def iterator(self) do
    Exts.Table.Iterator.new(self, reverse: false)
  end

  def reverse_iterator(self) do
    Exts.Table.Iterator.new(self, reverse: true)
  end

  @spec delete(any, t) :: true
  def delete(key, table(id: id)) do
    Exts.delete(id, key)
  end

  @spec delete!(record, t) :: true
  def delete!(object, table(id: id)) do
    Exts.delete!(id, object)
  end

  @spec write(record, t)            :: boolean
  @spec write(record, Keyword.t, t) :: boolean
  def write(object, options // [], table(id: id)) do
    Exts.write(id, object, options)
  end
end

defimpl Access, for: Exts.Table do
  def access(table, key) do
    table.read(key)
  end
end

# TODO: more performant iterator, seriously
defimpl Enum.Iterator, for: Exts.Table do
  def iterator(self) do
    Enum.Iterator.iterator(self.iterator)
  end

  def count(self) do
    self.size
  end
end
