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

  defrecordp :dict, table: nil

  @doc """
  Create a new empty dict.
  """
  @spec new :: Dict.t
  def new(options // []) do
    dict(table: Exts.Table.new(options))
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
    if table.contains?(key) do
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
    case table.contains?(key) do
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
  Returns the dict size.
  """
  def size(dict(table: table)) do
    table.count
  end

  @doc """
  Clear the table.
  """
  def empty(dict(table: table)) do
    table.clear
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

defimpl Enum.Iterator, for: Exts.Dict do
  def iterator(self) do
    Enum.Iterator.iterator(Exts.Dict.to_table(self))
  end

  def count(self) do
    Enum.Iterator.count(Exts.Dict.to_table(self))
  end
end

defimpl Access, for: Exts.Dict do
  def access(self, key) do
    Exts.Dict.get(self, key, nil)
  end
end

defimpl Binary.Inspect, for: Exts.Dict do
  def inspect(dict, opts) do
    "#Exts.Dict<" <> Kernel.inspect(Exts.Dict.to_list(dict), opts) <> ">"
  end
end
