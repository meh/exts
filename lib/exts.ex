#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts do
  defexception FileError, reason: nil do
    @moduledoc """
    Exception thrown if an error occurs on loading or dumping a table.
    """

    @spec message(t) :: String.t
    def message(FileError[reason: reason]) do
      reason
    end
  end

  @type table :: integer | atom

  @doc """
  Load a table from the given file, see `ets:file2tab`.
  """
  @spec load(String.t) :: { :ok, table } | { :error, any }
  @spec load(String.t, Keyword.t) :: { :ok, table } | { :error, any }
  def load(path, options // []) do
    :ets.file2tab(path, options)
  end

  @doc """
  Load a table from the given file, raising if there's any problem doing so,
  see `ets:file2tab`.
  """
  @spec load!(String.t) :: table | no_return
  @spec load!(String.t, Keyword.t) :: table | no_return
  def load!(path, options // []) do
    case :ets.file2tab(path, options) do
      { :ok, table } ->
        table

      { :error, reason } ->
        raise FileError, reason: reason
    end
  end

  @doc """
  Dump the given table to the given file, see `ets:tab2file`.
  """
  @spec dump(table, String.t) :: :ok | { :error, any }
  @spec dump(table, String.t, Keyword.t) :: :ok | { :error, any }
  def dump(table, path, options // []) do
    :ets.tab2file(table, path, options)
  end

  @doc """
  Dump the given table to the given file, raising if there's any problem doing
  so, see `ets:tab2file`.
  """
  @spec dump!(table, String.t) :: :ok | no_return
  @spec dump!(table, String.t, Keyword.t) :: :ok | no_return
  def dump!(table, path, options // []) do
    case :ets.tab2file(table, path, options) do
      :ok ->
        :ok

      { :error, reason } ->
        raise FileError, reason: reason
    end
  end

  @doc """
  Get information about the given table or table saved on file, see `ets:info`
  and `ets:tabfile_info`.
  """
  @spec info(String.t | table) :: { :ok, any } | { :error, any } | Keyword.t | nil
  def info(path) when is_binary path do
    :ets.tabfile_info(path)
  end

  def info(table) do
    case :ets.info(table) do
      :undefined -> nil
      value      -> value
    end
  end

  @doc """
  Get specific information about the given table and given topic, see
  `ets:info`.
  """
  @spec info(table, atom) :: any | nil
  def info(table, key) do
    case :ets.info(table, key) do
      :undefined -> nil
      value      -> value
    end
  end

  @doc """
  Rename the given table to the given name, see `ets:rename`.
  """
  @spec rename(table, atom) :: atom
  def rename(table, name) do
    :ets.rename(table, name)
  end

  @doc """
  Get all the present tables, see `ets:all`.
  """
  @spec all :: [table]
  def all do
    :ets.all
  end

  @doc """
  Convert the given table to a list of records, see `ets:tab2list`.
  """
  @spec to_list(table) :: [record]
  def to_list(table) do
    :ets.tab2list(table)
  end

  @doc """
  Create a new unnamed table with the default options, see `ets:new`.
  """
  @spec new :: table
  def new do
    :ets.new(nil, [])
  end

  @doc """
  Create a new unnamed table with the given options, see `ets:new`.
  """
  @spec new(Keyword.t) :: table
  def new(options) do
    new(nil, options)
  end

  @doc """
  Create a new named table with the given options, see `ets:new`.

  ## Options

  * `:index` sets the position of the key in the tuple, default is 0.
  * `:concurrency` can be either `:both`, `:write` or `:read`, it sets
    `:write_concurrency` and `:read_concurrency` appropriately.
  * `:type` can either be `:set`, `:ordered_set`, `:bag` or `:duplicate_bag`,
    default is `:set`
  * `:access` can either be `:public`, `:protected`, `:private`, default is
    `:protected`.
  * `:heir` sets a heir for the table, see the documentation of `ets:new`,
     default is none.
  * `:compressed` can be either true or false, default is false
  """
  @spec new(atom, Keyword.t) :: table
  def new(name, options) do
    args = []

    if name do
      args = [:named_table | args]
    end

    args = [{ :keypos, (options[:index] || 0) + 1 } | args]

    args = case options[:concurrency] do
      :both  -> [{ :write_concurrency, true  }, { :read_concurrency, true  } | args]
      :write -> [{ :write_concurrency, true  }, { :read_concurrency, false } | args]
      :read  -> [{ :write_concurrency, false }, { :read_concurrency, true  } | args]
      _      -> args
    end

    args = case options[:type] do
      :set           -> [:set | args]
      :ordered_set   -> [:ordered_set | args]
      :bag           -> [:bag | args]
      :duplicate_bag -> [:duplicate_bag | args]
      _              -> args
    end

    args = case options[:access] do
      :public    -> [:public | args]
      :protected -> [:protected | args]
      :private   -> [:private | args]
      _          -> args
    end

    args = if options[:heir] do
      [{ :heir, options[:heir][:pid], options[:heir][:data] } | args]
    else
      [{ :heir, :none } | args]
    end

    if options[:compressed] do
      args = [:compressed | args]
    end

    :ets.new(name, args)
  end

  @doc """
  Give the given table to the given process, see `ets:give_away`.
  """
  @spec give_to(table, pid)      :: true
  @spec give_to(table, pid, any) :: true
  def give_to(table, pid, data // nil) do
    :ets.give_away(table, pid, data)
  end

  @doc """
  Clear the given table, see `ets:delete_all_objects`.
  """
  @spec clear(table) :: true
  def clear(table) do
    :ets.delete_all_objects(table)
  end

  @doc """
  Destroy the given table, see `ets:delete`.
  """
  @spec destroy(table) :: true
  def destroy(table) do
    :ets.delete(table)
  end

  @doc """
  Read the given record from the given table, see `ets:lookup`.
  """
  @spec read(table, any) :: [record]
  def read(table, key) do
    :ets.lookup(table, key)
  end

  @doc """
  Read the records in the given slot, see `ets:slot`.
  """
  @spec at(table, integer) :: [record]
  def at(table, slot) do
    case :ets.slot(table, slot) do
      :'$end_of_table' -> nil
      r                -> r
    end
  end

  @doc """
  Get the first key in the given table, see `ets:first`.
  """
  @spec first(table) :: any | nil
  def first(table) do
    case :ets.first(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the next key in the given table, see `ets:next`.
  """
  @spec next(table, any) :: any | nil
  def next(table, key) do
    case :ets.next(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the previous key in the given table, see `ets:prev`.
  """
  @spec prev(table, any) :: any | nil
  def prev(table, key) do
    case :ets.prev(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @doc """
  Get the last key in the given table, see `ets:prev`.
  """
  @spec last(table) :: any | nil
  def last(table) do
    case :ets.last(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  defmodule Selection do
    @moduledoc """
    Selection wraps an `ets:select` result, which may or may not contain a
    continuation, in case of continuations you can access the next set of
    values by calling `.next`.
    """

    @opaque t :: record

    defrecordp :selection, values: [], continuation: nil, reverse: false

    @doc """
    Get a Selection from the various select results.
    """
    @spec new(:'$end_of_table' | list | { list, any }) :: t | nil
    def new(value, reverse // false) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> selection(values: v, continuation: c, reverse: reverse)
        [_ | _]  -> selection(values: value, reverse: reverse)
      end
    end

    @doc """
    Check if the Selection is traversing in reverse.
    """
    @spec reverse?(t) :: boolean
    def reverse?(selection(reverse: reverse)) do
      reverse
    end

    @doc """
    Get the values in the current Selection.
    """
    @spec values(t) :: [any]
    def values(selection(values: v)) do
      v
    end

    @doc """
    Get the next set of values wrapped in another Selection, returns nil if
    there are no more.
    """
    @spec next(t) :: t | nil
    def next(selection(continuation: nil)) do
      nil
    end

    def next(selection(reverse: false, continuation: c)) do
      new(:ets.select(c))
    end

    def next(selection(reverse: true, continuation: c)) do
      new(:ets.select_reverse(c), true)
    end
  end

  @doc """
  Select records in the given table using a match_spec, see `ets:select`.
  """
  @spec select(table, any) :: Selection.t | nil
  def select(table, match_spec) do
    Selection.new(:ets.select(table, match_spec))
  end

  @doc """
  Select records in the given table using a match_spec passing a limit, see
  `ets:select`.
  """
  @spec select(table, non_neg_integer, any) :: Selection.t | nil
  def select(table, limit, match_spec) when is_integer limit do
    Selection.new(:ets.select(table, match_spec, limit))
  end

  @doc """
  Select records in the given table using a match_spec, traversing in reverse,
  see `ets:select_reverse`.
  """
  @spec reverse_select(table, any) :: Selection.t | nil
  def reverse_select(table, match_spec) do
    Selection.new(:ets.select_reverse(table, match_spec), true)
  end

  @doc """
  Select records in the given table using a match_spec passing a limit,
  traversing in reverse, see `ets:select_reverse`.
  """
  def reverse_select(table, limit, match_spec) do
    Selection.new(:ets.select_reverse(table, match_spec, limit), false)
  end

  defmodule Match do
    @moduledoc """
    Match wraps an `ets:match` or `ets:match_object` result, which may or may
    not contain a continuation, in case of continuations you can access the
    next set of values by calling `.next`.
    """

    @opaque t :: record

    defrecordp :match, values: [], continuation: nil, whole: false

    @doc """
    Get a Match from the various match results.
    """
    def new(value, whole // false) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> match(values: v, continuation: c, whole: whole)
        [_ | _]  -> match(values: value, whole: whole)
      end
    end

    @doc """
    Check if the Match is matching whole objects.
    """
    @spec whole?(t) :: boolean
    def whole?(match(whole: whole)) do
      whole
    end

    @doc """
    Get the values in the current Match.
    """
    @spec values(t) :: [any]
    def values(match(values: v)) do
      v
    end

    @doc """
    Get the next set of values wrapped in another Match, returns nil if there
    are no more.
    """
    @spec next(t) :: Match.t | nil
    def next(match(continuation: nil)) do
      nil
    end

    def next(match(whole: true, continuation: c)) do
      new(:ets.match_object(c))
    end

    def next(match(whole: false, continuation: c)) do
      new(:ets.match(c))
    end
  end

  @doc """
  Match records from the given table with the given pattern, see `ets:match`.
  """
  @spec match(table, any) :: Match.t | nil
  def match(table, pattern) do
    Match.new(:ets.match(table, pattern))
  end

  @doc """
  Match records from the given table with the given pattern and options or
  limit, see `ets:match`.

  ## Options

  * `:whole` when true it returns the whole record.
  * `:delete` when true it deletes the matching records instead of returning
    them.
  """
  @spec match(table, any | integer, Keyword.t | any) :: Match.t | nil
  def match(table, pattern, delete: true) do
    :ets.match_delete(table, pattern)
  end

  def match(table, pattern, whole: true) do
    Match.new(:ets.match_object(table, pattern))
  end

  def match(table, limit, pattern) when is_integer limit do
    Match.new(:ets.match(table, pattern, limit))
  end

  @doc """
  Match record from the given table with the given pattern, options and limit,
  see `ets:match_object`.
  """
  @spec match(table, integer, any, Keyword.t) :: Match.t | nil
  def match(table, limit, pattern, whole: true) do
    Match.new(:ets.match_object(table, pattern, limit))
  end

  @doc """
  Get the number of records in the given table.
  """
  @spec count(table) :: non_neg_integer
  def count(table) do
    info(table, :size)
  end

  @doc """
  Count the number of records matching the match_spec, see `ets:select_count`.
  """
  @spec count(table, any) :: non_neg_integer
  def count(table, match_spec) do
    :ets.select_count(table, match_spec)
  end

  @doc """
  Fold the given table from the left, see `ets:foldl`.
  """
  @spec foldl(table, any, (record, any -> any)) :: any
  def foldl(table, acc, fun) do
    :ets.foldl(fun, acc, table)
  end

  @doc """
  Fold the given table from the right, see `ets:foldr`.
  """
  @spec foldr(table, any, (record, any -> any)) :: any
  def foldr(table, acc, fun) do
    :ets.foldr(fun, acc, table)
  end

  @doc """
  Delete the record matching the given pattern or key in the given table, see
  `ets:select_delete` and `ets:delete`.
  """
  @spec delete(table, any) :: true | integer
  def delete(table, [{ _, _, _ } | _] = match_spec) do
    :ets.select_delete(table, match_spec)
  end

  def delete(table, key) do
    :ets.delete(table, key)
  end

  @doc """
  Delete the given record from the given table, see `ets:delete_object`.
  """
  @spec delete!(table, record) :: true
  def delete!(table, object) do
    :ets.delete_object(table, object)
  end

  # TODO: udpate_counter and update_element

  @doc """
  Write the given record to the given table optionally disabling overwriting,
  see `ets:insert` and `ets:insert_new`.
  """
  @spec write(table, record, Keyword.t) :: boolean
  def write(table, object, options // []) do
    if options[:overwrite] == false do
      :ets.insert_new(table, object)
    else
      :ets.insert(table, object)
    end
  end
end
