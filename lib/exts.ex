#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts do
  @doc false
  defmacro __using__(_opts) do
    quote do
      require Exts
      require Exts.Table
    end
  end

  @type table :: integer | atom

  @spec load(String.t) :: { :ok, table } | { :error, any }
  @spec load(String.t, Keyword.t) :: { :ok, table } | { :error, any }
  def load(path, options // []) do
    :ets.file2tab(path, options)
  end

  @spec dump(table, String.t) :: :ok | { :error, any }
  @spec dump(table, String.t, Keyword.t) :: :ok | { :error, any }
  def dump(table, path, options // []) do
    :ets.tab2file(table, path, options)
  end

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

  @spec info(table, atom) :: any | nil
  def info(table, key) do
    case :ets.info(table, key) do
      :undefined -> nil
      value      -> value
    end
  end

  @spec rename(table, atom) :: atom
  def rename(table, name) do
    :ets.rename(table, name)
  end

  @spec all :: [table]
  def all do
    :ets.all
  end

  @spec to_list(table) :: [record]
  def to_list(table) do
    :ets.tab2list(table)
  end

  @spec new :: table
  def new do
    :ets.new(nil, [])
  end

  @spec new(Keyword.t) :: table
  def new(options) do
    new(nil, options)
  end

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

  @spec give_to(table, pid)      :: true
  @spec give_to(table, pid, any) :: true
  def give_to(table, pid, data // nil) do
    :ets.give_away(table, pid, data)
  end

  @spec clear(table) :: true
  def clear(table) do
    :ets.delete_all_objects(table)
  end

  @spec destroy(table) :: true
  def destroy(table) do
    :ets.delete(table)
  end

  @spec read(table, any) :: [record]
  def read(table, key) do
    :ets.lookup(table, key)
  end

  @spec at(table, integer) :: [record]
  def at(table, slot) do
    case :ets.slot(table, slot) do
      :'$end_of_table' -> nil
      r                -> r
    end
  end

  @spec first(table) :: any | nil
  def first(table) do
    case :ets.first(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @spec next(table, any) :: any | nil
  def next(table, key) do
    case :ets.next(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @spec prev(table, any) :: any | nil
  def prev(table, key) do
    case :ets.prev(table, key) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  @spec last(table) :: any | nil
  def last(table) do
    case :ets.last(table) do
      :"$end_of_table" -> nil
      key              -> key
    end
  end

  defmodule Selection do
    @opaque t :: record

    defrecordp :selection, values: [], continuation: nil, reverse: false

    def new(value, reverse // false) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> selection(values: v, continuation: c, reverse: reverse)
        [_ | _]  -> selection(values: value, reverse: reverse)
      end
    end

    def reverse?(selection(reverse: reverse)) do
      reverse
    end

    def values(selection(values: v)) do
      v
    end

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

  def select(table, match_spec) do
    Selection.new(:ets.select_reverse(table, match_spec))
  end

  def select(table, limit, match_spec) when is_integer limit do
    Selection.new(:ets.select(table, match_spec, limit))
  end

  def reverse_select(table, match_spec) do
    Selection.new(:ets.select_reverse(table, match_spec), true)
  end

  def reverse_select(table, limit, match_spec) do
    Selection.new(:ets.select(table, match_spec, limit), false)
  end

  defmodule Match do
    @opaque t :: record

    defrecordp :match, values: [], continuation: nil, whole: false

    def new(value, whole // false) do
      case value do
        :'$end_of_table' -> nil
        []               -> nil
        { [], _ }        -> nil

        { v, c } -> match(values: v, continuation: c, whole: whole)
        [_ | _]  -> match(values: value, whole: whole)
      end
    end

    def whole?(match(whole: whole)) do
      whole
    end

    def values(match(values: v)) do
      v
    end

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

  @spec match(table, any) :: Match.t | nil
  def match(table, pattern) do
    Match.new(:ets.match(table, pattern))
  end

  @spec match(table, any | integer, Keyword.t | any) :: Match.t | nil
  def match(table, pattern, delete: true) do
    Match.new(:ets.match_delete(table, pattern))
  end

  def match(table, pattern, whole: true) do
    Match.new(:ets.match_object(table, pattern))
  end

  def match(table, limit, pattern) when is_integer limit do
    Match.new(:ets.match(table, pattern, limit))
  end

  @spec match(table, integer, any, Keyword.t) :: Match.t | nil
  def match(table, limit, pattern, whole: true) do
    Match.new(:ets.match_object(table, pattern, limit))
  end

  @spec count(table) :: non_neg_integer
  def count(table) do
    size(table)
  end

  @spec count(table, any) :: non_neg_integer
  def count(table, match_spec) do
    :ets.select_count(table, match_spec)
  end

  @spec foldl(table, any, (record, any -> any)) :: any
  def foldl(table, acc, fun) do
    :ets.foldl(fun, acc, table)
  end

  @spec foldr(table, any, (record, any -> any)) :: any
  def foldr(table, acc, fun) do
    :ets.foldr(fun, acc, table)
  end

  @spec delete(table, any) :: true | integer
  def delete(table, [{ _, _, _ } | _] = match_spec) do
    :ets.select_delete(table, match_spec)
  end

  def delete(table, key) do
    :ets.delete(table, key)
  end

  @spec delete!(table, record) :: true
  def delete!(table, object) do
    :ets.delete_object(table, object)
  end

  # TODO: udpate_counter and update_element

  @spec write(table, record, Keyword.t) :: boolean
  def write(table, object, options // []) do
    if options[:overwrite] == false do
      :ets.insert_new(table, object)
    else
      :ets.insert(table, object)
    end
  end
end
