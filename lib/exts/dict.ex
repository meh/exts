#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Dict do
  @moduledoc """
  Wraps an ets table into a Dict interface, keep in mind this Dict is
  **mutable**.
  """

  @behaviour Dict

  defrecordp :dict, __MODULE__, table: nil

  @doc """
  Create a new empty dict.
  """
  @spec new :: Dict.t
  def new(options // []) do
    dict(table: Exts.Table.new(options))
  end

  @doc """
  Wrap a table into an Exts.Dict.
  """
  @spec from_table(Exts.Table.t) :: Dict.t
  def from_table(table) do
    dict(table: table)
  end

  @doc """
  Puts the given key and value in the dict.
  """
  def put(dict(table: table) = self, key, value) do
    table.write({ key, value })

    self
  end

  @doc """
  Puts the given value under key in the dictionary only if one does not exist
  yet.
  """
  def put_new(dict(table: table) = self, key, value) do
    table.write({ key, value }, overwrite: false)

    self
  end

  @doc """
  Updates the key in the dictionary according to the given function.

  Raises if the key does not exist in the dictionary.
  """
  def update(dict(table: table) = self, key, fun) when is_function(fun, 1) do
    if table.member?(key) do
      { _, value } = table.read(key)

      table.write({ key, fun.(value) })
    else
      raise KeyError, key: key
    end

    self
  end

  @doc """
  Updates the key in the dictionary according to the given function. Adds
  initial value if the key does not exist in the dicionary.
  """
  def update(dict(table: table) = self, key, value, fun) when is_function(fun, 1) do
    table.write({ key, value }, overwrite: false)
    table.write({ key, fun.(elem table.read(key), 1) })

    self
  end

  @doc """
  Gets the value under key from the dict.
  """
  def get(dict(table: table), key, default // nil) do
    case table.read(key) do
      { _, value } -> value
      nil          -> default
    end
  end

  @doc """
  Gets the value under key from the dict, raises KeyError if such key does not
  exist.
  """
  def get!(dict(table: table), key) do
    case table.read(key) do
      { _, value } -> value
      nil          -> raise KeyError, key: key
    end
  end

  @doc """
  Checks if the dict has the given key.
  """
  def has_key?(dict(table: table), key) do
    case table.member?(key) do
      nil -> false
      _   -> true
    end
  end

  @doc """
  Deletes a value from the dict.
  """
  def delete(dict(table: table) = self, key) do
    table.delete(key)

    self
  end

  @doc """
  Drops the keys from the given dict.
  """
  def drop(self, keys) do
    Enum.each keys, delete(self, &1)

    self
  end

  @doc """
  Checks if the two dicts are the same.
  """
  def equal?(dict(table: table), dict(table: other)) do
    # XXX: should it check the contents too?
    table.id == other.id
  end

  @doc """
  Returns the value under key from the dict and deletes it.
  """
  def pop(self, key, default // nil) do
    value = get(self, key, default)
    delete(self, key)

    { value, self }
  end

  @doc """
  Splits a dict into two dicts, one containing entries with key in the keys list,
  and another containing entries with key not in keys.

  Returns a 2-tuple of the new dicts.

  Keep in mind this **creates two new ets tables**, use sparingly.
  """
  def split(self, keys) do
    first  = Exts.Dict.new
    second = Exts.Dict.new

    Enum.each self, fn { key, value } ->
      if key in keys do
        put(first, key, value)
      else
        put(second, key, value)
      end
    end

    { first, second }
  end

  @doc """
  Returns a new dict with only the entries which key is in keys.

  Keep in mind this **creates a new ets table**, use sparingly.
  """
  def take(self, keys) do
    result = Exts.Dict.new

    Enum.each keys, fn key ->
      if has_key?(self, key) do
        put(result, key, get(self, key))
      end
    end

    result
  end

  @doc """
  Returns the dict size.
  """
  def size(dict(table: table)) do
    table.count
  end

  @doc """
  Clear the table.
  """
  def empty(dict(table: table) = self) do
    table.clear
    self
  end

  @doc """
  Converts the dict to a list.
  """
  def to_list(dict(table: table)) do
    table.to_list
  end

  @doc """
  Get all keys in the dict.
  """
  def keys(dict(table: table)) do
    case table.select([{{ :'$1', :'$2' }, [], [:'$1'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  @doc """
  Get all values in the dict.
  """
  def values(dict(table: table)) do
    case table.select([{{ :'$1', :'$2' }, [], [:'$2'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  @doc """
  Merges the other dictionary into the current one.
  """
  def merge(dict(table: table) = self, other, callback // fn(_, _, v) -> v end) do
    Enum.each other, fn { k, v } ->
      case Exts.read(table.id, k) do
        []  -> put(self, k, v)
        [r] -> put(self, k, callback.(k, r, v))
      end
    end

    self
  end

  @doc """
  Returns the table wrapped by the dict.
  """
  @spec to_table(Dict.t) :: Exts.Table.t
  def to_table(dict(table: table)) do
    table
  end
end

defimpl Data.Dictionary, for: Exts.Dict do
  defdelegate get(self, key), to: Exts.Dict
  defdelegate get(self, key, default), to: Exts.Dict
  defdelegate get!(self, key), to: Exts.Dict
  defdelegate put(self, key, value), to: Exts.Dict
  defdelegate delete(self, key), to: Exts.Dict
  defdelegate keys(self), to: Exts.Dict
  defdelegate values(self), to: Exts.Dict
end

defimpl Data.Emptyable, for: Exts.Dict do
  def empty?(self) do
    Exts.Dict.size(self) == 0
  end

  def clear(self) do
    Exts.Dict.empty(self)
  end
end

defimpl Data.Counted, for: Exts.Dict do
  defdelegate count(self), to: Exts.Dict, as: :size
end

defimpl Data.Listable, for: Exts.Dict do
  defdelegate to_list(self), to: Exts.Dict
end

defimpl Data.Contains, for: Exts.Dict do
  defdelegate contains?(self, key), to: Exts.Dict, as: :has_key?
end

defimpl Data.Reducible, for: Exts.Dict do
  def reduce(self, acc, fun) do
    self.to_table.foldl(self, acc, fun)
  end
end

defimpl Enumerable, for: Exts.Dict do
  def reduce(self, acc, fun) do
    Exts.Dict.to_table(self).foldl(acc, fun)
  end

  def member?(self, key) do
    self.to_table.member?(key)
  end

  def count(self) do
    Exts.Dict.to_table(self).count
  end
end

defimpl Access, for: Exts.Dict do
  def access(self, key) do
    Exts.Dict.get(self, key, nil)
  end
end

defimpl Inspect, for: Exts.Dict do
  import Inspect.Algebra

  def inspect(dict, opts) do
    concat ["#Exts.Dict<", Kernel.inspect(Exts.Dict.to_list(dict), opts), ">"]
  end
end
