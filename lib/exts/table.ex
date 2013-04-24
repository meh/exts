#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Table do
  @opaque t :: { Exts.Table, Exts.table, :bag | :duplicate_bag | :set | :oredered_set }

  defrecordp :table, id: nil, type: nil, resource: nil

  @doc """
  Create a new table with default options.
  """
  @spec new :: t
  def new do
    new([])
  end

  @doc """
  Wrap a table or create one with the passed options.

  If automatic mode isn't disabled, smart garbage collection will be used,
  access will be forced to public and heir will be forced to Exts.Manager.

  Smart garbage collection implies tables won't die with processes and they
  will be destroyed when they aren't referenced by anything anymore.

  The Exts.Manager process will be set as heir and you'll be able to retake
  ownership of a table if wanted.
  """
  @spec new(integer | atom | Keyword.t) :: t
  def new(options) when is_list options do
    if options[:automatic] != false do
      options = Keyword.put(options, :heir, pid: Process.whereis(Exts.Manager))
      options = Keyword.put(options, :access, :public)

      id       = Exts.new(options)
      resource = if options[:automatic] != false do
        Finalizer.define({ :destroy, id }, Process.whereis(Exts.Manager))
      end

      table(id: id, type: options[:type] || :set, resource: resource)
    else
      table(id: Exts.new(options), type: options[:type] || :set)
    end
  end

  def new(id) do
    table(id: id, type: :ets.info(id, :type))
  end

  @doc """
  Get the id of the table, usable with the raw :ets functions or Exts wrapped
  ones.
  """
  @spec id(t) :: integer | atom
  def id(table(id: id)) do
    id
  end

  @doc """
  Rename the table to the given atom, see `ets:rename`.
  """
  @spec rename(atom, t) :: atom
  def rename(name, table(id: id)) do
    Exts.rename(id, name)
  end

  @doc """
  Give the table to another process, optionally passing data to give to the
  process, see `ets:give_away`.
  """
  @spec give_to(pid, t) :: true
  @spec give_to(pid, any, t) :: true
  def give_to(pid, data // nil, table(id: id)) do
    Exts.give_to(id, pid, data)
  end

  @doc """
  Load a table from a file, see `ets:file2tab`.
  """
  @spec load(String.t)            :: { :ok, t } | { :error, any }
  @spec load(String.t, Keyword.t) :: { :ok, t } | { :error, any }
  def load(path, options // []) do
    case :ets.file2tab(path, options) do
      { :ok, id } ->
        { :ok, new(id) }

      { :error, reason } ->
        { :error, reason }
    end
  end

  @doc """
  Load a table from a file, raising if there's a problem with the file, see
  `ets:file2tab`.
  """
  @spec load!(String.t)            :: t | no_return
  @spec load!(String.t, Keyword.t) :: t | no_return
  def load!(path, options // []) do
    case :ets.file2tab(path, options) do
      { :ok, id } ->
        new(id)

      { :error, reason } ->
        raise Exts.FileError, reason: reason
    end
  end

  @doc """
  Dump the table to a file.
  """
  @spec dump(String.t, t) :: :ok | { :error, any }
  @spec dump(String.t, Keyword.t, t) :: :ok | { :error, any }
  def dump(path, options // [], table(id: id)) do
    :ets.tab2file(id, path, options)
  end

  @doc """
  Dump the table to a file, raising if there's a problem while doing so.
  """
  @spec dump!(String.t, t) :: :ok | no_return
  @spec dump!(String.t, Keyword.t, t) :: :ok | no_return
  def dump!(path, options // [], table(id: id)) do
    case :ets.tab2file(id, path, options) do
      :ok ->
        :ok

      { :error, reason } ->
        raise Exts.FileError, reason: reason
    end
  end

  @doc """
  Protect the table while running the passed function, useful to make iterating
  safe, see `ets:safe_fixtable`.
  """
  @spec protect(function, t) :: any
  def protect(fun, table(id: id) = self) do
    :ets.safe_fixtable(id, true)

    try do
      cond do
        is_function(fun, 0) -> fun.()
        is_function(fun, 1) -> fun.(self)
      end
    after
      :ets.safe_fixtable
    end
  end

  @doc """
  Check if the table is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(table(type: type)) do
    type == :bag
  end

  @doc """
  Check if the table is a duplicate bag.
  """
  @spec duplicate_bag?(t) :: boolean
  def duplicate_bag?(table(type: type)) do
    type == :duplicate_bag
  end

  @doc """
  Check if the table is a set.
  """
  @spec set?(t) :: boolean
  def set?(table(type: type)) do
    type == :set
  end

  @doc """
  Check if the table is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(table(type: type)) do
    type == :ordered_set
  end

  @doc """
  Get info about the table, see `ets:info`.
  """
  @spec info(t, atom) :: any | nil
  def info(key, table(id: id)) do
    Exts.info(id, key)
  end

  @doc """
  Convert the table to a list, see `ets:tab2list`.
  """
  @spec to_list(t) :: [record]
  def to_list(table(id: id)) do
    Exts.to_list(id)
  end

  @doc """
  Clear the contents of the table, see `ets:delete_all_objects`.
  """
  @spec clear(t) :: true
  def clear(table(id: id)) do
    Exts.clear(id)
  end

  @doc """
  Destroy the table, see `ets:delete`.
  """
  @spec destroy(t) :: true
  def destroy(table(id: id)) do
    Exts.destroy(id)
  end

  @doc """
  Check if the table contains the given key.
  """
  @spec contains?(any, t) :: boolean
  def contains?(key, table(id: id)) do
    case Exts.read(id, key) do
      [] -> false
      _  -> true
    end
  end

  @doc """
  Read a records from the table, if it's a set or ordered set it returns a
  single record, otherwise it returns a list of records, see `ets:lookup`.
  """
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

  @doc """
  Read the records in the given slot, see `ets:slot`.
  """
  @spec at(integer, t) :: [record]
  def at(slot, table(id: id)) do
    Exts.at(id, slot)
  end

  @doc """
  Get the first key in table, see `ets:first`.
  """
  @spec first(t) :: any
  def first(table(id: id)) do
    Exts.first(id)
  end

  @doc """
  Get the next key in the table, see `ets:next`.
  """
  @spec next(any, t) :: any
  def next(key, table(id: id)) do
    Exts.next(id, key)
  end

  @doc """
  Get the previous key in the table, see `ets:prev`.
  """
  @spec prev(any, t) :: any
  def prev(key, table(id: id)) do
    Exts.prev(id, key)
  end

  @doc """
  Get the last key in the table, see `ets:last`.
  """
  @spec last(t) :: any
  def last(table(id: id)) do
    Exts.last(id)
  end

  @doc """
  Select records in the table using a match_spec, see `ets:select`.
  """
  @spec select(any, t) :: [any]
  def select(match_spec, table(id: id)) do
    Exts.select(id, match_spec)
  end

  @doc """
  Select records in the table using a match_spec and passing a limit,
  `ets:select`.
  """
  @spec select(integer, any, t) :: [any]
  def select(limit, match_spec, table(id: id)) do
    Exts.select(limit, id, match_spec)
  end

  @doc """
  Select records in the table using a match_spec, traversing in reverse, see
  `ets:select_reverse`.
  """
  @spec reverse_select(any, t) :: [any]
  def reverse_select(match_spec, table(id: id)) do
    Exts.reverse_select(id, match_spec)
  end

  @doc """
  Select records in the table using a match_spec and passing a limit,
  traversing in reverse, `ets:select_reverse`.
  """
  @spec reverse_select(integer, any, t) :: [any]
  def reverse_select(limit, match_spec, table(id: id)) do
    Exts.reverse_select(limit, id, match_spec)
  end

  @doc """
  Match records from the table with the given pattern, see `ets:match`.
  """
  @spec match(any, t) :: Match.t | nil
  def match(pattern, table(id: id)) do
    Exts.match(id, pattern)
  end

  @doc """
  Match records from the table with the given pattern and options or limit, see
  `ets:match`.
  """
  @spec match(any | integer, Keyword.t | any, t) :: Match.t | nil
  def match(limit_or_pattern, options_or_pattern, table(id: id)) do
    Exts.match(id, limit_or_pattern, options_or_pattern)
  end

  @doc """
  Match records from the table with the given pattern, options and limit, see
  `ets:match`.
  """
  @spec match(integer, any, Keyword.t, t) :: Match.t | nil
  def match(limit, pattern, options, table(id: id)) do
    Exts.match(id, limit, pattern, options)
  end

  @doc """
  Get the number of records in the table.
  """
  @spec count(t) :: non_neg_integer
  def count(table(id: id)) do
    Exts.count(id)
  end

  @doc """
  Count the number of records matching the match_spec, see `ets:select_count`.
  """
  @spec count(any, t) :: non_neg_integer
  def count(spec, table(id: id)) do
    Exts.count(id, spec)
  end

  @doc """
  Fold the table from the left, see `ets:foldl`.
  """
  @spec foldl(any, (record, any -> any), t) :: any
  def foldl(acc, fun, table(id: id)) do
    Exts.foldl(id, acc, fun)
  end

  @doc """
  Fold the table from the right, see `ets:foldr`.
  """
  @spec foldr(any, (record, any -> any), t) :: any
  def foldr(acc, fun, table(id: id)) do
    Exts.foldr(id, acc, fun)
  end

  @doc """
  Return an iterator for the table.
  """
  @spec iterator(t) :: Exts.Table.Iterator.t
  def iterator(self) do
    Exts.Table.Iterator.new(self, reverse: false)
  end

  @doc """
  Return a reverse iterator for the table.
  """
  @spec reverse_iterator(t) :: Exts.Table.Iterator.t
  def reverse_iterator(self) do
    Exts.Table.Iterator.new(self, reverse: true)
  end

  @doc """
  Delete the record matching the given match_spec or key, see
  `ets:select_delete` and `ets:delete`.
  """
  @spec delete(any, t) :: true
  def delete(key_or_pattern, table(id: id)) do
    Exts.delete(id, key_or_pattern)
  end

  @doc """
  Delete the given record from the table, see `ets:delete_object`.
  """
  @spec delete!(record, t) :: true
  def delete!(object, table(id: id)) do
    Exts.delete!(id, object)
  end

  @doc """
  Write the given record to the table optionally disabling overwriting, see
  `ets:insert` and `ets:insert_new`.
  """
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

defimpl Enum.Iterator, for: Exts.Table do
  def iterator(self) do
    Enum.Iterator.iterator(self.iterator)
  end

  def count(self) do
    self.count
  end
end

defimpl Binary.Inspect, for: Exts.Table do
  def inspect(self, _opts) do
    "#Exts.Table<#{self.id}>"
  end
end
