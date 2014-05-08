#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Dict do
  defstruct [:id, :type]

  alias __MODULE__, as: T

  use Dict.Behaviour

  @doc """
  Create a new table with default options.
  """
  @spec new :: t
  def new do
    new([])
  end

  @doc """
  Wrap a table or create one with the passed options.
  """
  @spec new(integer | atom | Keyword.t) :: t
  def new(options) when options |> is_list do
    %T{id: Exts.new(options), type: options[:type] || :set}
  end

  def new(id) do
    %T{id: id, type: :ets.info(id, :type)}
  end

  @doc """
  Protect a table for safe iteration.
  """
  @spec protect(t) :: none
  def protect(%T{id: id}) do
    :ets.safe_fixtable(id, true)
  end

  @doc """
  Unprotect a table from safe iteration.
  """
  @spec unprotect(t) :: none
  def unprotect(%T{id: id}) do
    :ets.safe_fixtable(id, false)
  end

  @doc """
  Rename the table to the given atom, see `ets:rename`.
  """
  @spec rename(atom, t) :: atom
  def rename(name, %T{id: id}) do
    Exts.rename(id, name)
  end

  @doc """
  Give the table to another process, optionally passing data to give to the
  process, see `ets:give_away`.
  """
  @spec give_to(t, pid) :: true
  @spec give_to(t, pid, any) :: true
  def give_to(%T{id: id}, pid, data \\ nil) do
    Exts.give_to(id, pid, data)
  end

  @doc """
  Load a table from a file, see `ets:file2tab`.
  """
  @spec load(String.t)            :: { :ok, t } | { :error, any }
  @spec load(String.t, Keyword.t) :: { :ok, t } | { :error, any }
  def load(path, options \\ []) do
    if path |> is_binary do
      path = String.from_char_list!(path)
    end

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
  def load!(path, options \\ []) do
    case load(path, options) do
      { :ok, table } ->
        table

      { :error, reason } ->
        raise Exts.FileError, reason: reason
    end
  end

  @doc """
  Dump the table to a file.
  """
  @spec dump(String.t, t) :: :ok | { :error, any }
  @spec dump(String.t, Keyword.t, t) :: :ok | { :error, any }
  def dump(%T{id: id}, path, options \\ []) do
    if is_binary(path) do
      path = String.from_char_list!(path)
    end

    :ets.tab2file(id, path, options)
  end

  @doc """
  Dump the table to a file, raising if there's a problem while doing so.
  """
  @spec dump!(String.t, t) :: :ok | no_return
  @spec dump!(String.t, Keyword.t, t) :: :ok | no_return
  def dump!(path, options \\ [], self) do
    case dump(path, options, self) do
      :ok ->
        :ok

      { :error, reason } ->
        raise Exts.FileError, reason: reason
    end
  end

  @doc """
  Check if the table is a bag.
  """
  @spec bag?(t) :: boolean
  def bag?(%T{type: type}) do
    type == :bag
  end

  @doc """
  Check if the table is a duplicate bag.
  """
  @spec duplicate_bag?(t) :: boolean
  def duplicate_bag?(%T{type: type}) do
    type == :duplicate_bag
  end

  @doc """
  Check if the table is a set.
  """
  @spec set?(t) :: boolean
  def set?(%T{type: type}) do
    type == :set
  end

  @doc """
  Check if the table is an ordered set.
  """
  @spec ordered_set?(t) :: boolean
  def ordered_set?(%T{type: type}) do
    type == :ordered_set
  end

  @doc """
  Get info about the table, see `ets:info`.
  """
  @spec info(t) :: [any] | nil
  def info(%T{id: id}) do
    Exts.info(id)
  end

  @doc """
  Get info about the table, see `ets:info`.
  """
  @spec info(atom, t) :: any | nil
  def info(%T{id: id}, key) do
    Exts.info(id, key)
  end

  def size(%T{id: id}) do
    Exts.count(id)
  end

  @doc """
  Delete the term matching the given match_spec or key, see
  `ets:select_delete` and `ets:delete`.
  """
  @spec delete(t, any) :: true
  def delete(%T{id: id}, key_or_pattern) do
    Exts.delete(id, key_or_pattern)
  end

  def put(%T{id: id} = self, key, value) do
    Exts.write id, { key, value }

    self
  end

  def fetch(%T{id: id, type: type}, key) when type in [:bag, :duplicate_bag] do
    case Exts.read(id, key) do
      [] ->
        :error

      values ->
        { :ok, for({ _, value } <- values, do: value) }
    end
  end

  def fetch(%T{id: id, type: type}, key) when type in [:set, :ordered_set] do
    case Exts.read(id, key) do
      [] ->
        :error

      [{ _, value }] ->
        { :ok, value }
    end
  end

  @doc """
  Convert the table to a list, see `ets:tab2list`.
  """
  @spec to_list(t) :: [term]
  def to_list(%T{id: id}) do
    Exts.to_list(id)
  end

  @doc """
  Clear the contents of the table, see `ets:delete_all_objects`.
  """
  @spec clear(t) :: true
  def clear(%T{id: id}) do
    Exts.clear(id)
  end

  @doc """
  Destroy the table, see `ets:delete`.
  """
  @spec destroy(t) :: true
  def destroy(%T{id: id}) do
    Exts.destroy(id)
  end

  @doc """
  Read the terms in the given slot, see `ets:slot`.
  """
  @spec at(integer, t) :: [term]
  def at(%T{id: id}, slot) do
    Exts.at(id, slot)
  end

  @doc """
  Get the first key in table, see `ets:first`.
  """
  @spec first(t) :: any
  def first(%T{id: id}) do
    Exts.first(id)
  end

  @doc """
  Get the next key in the table, see `ets:next`.
  """
  @spec next(any, t) :: any
  def next(%T{id: id}, key) do
    Exts.next(id, key)
  end

  @doc """
  Get the previous key in the table, see `ets:prev`.
  """
  @spec prev(any, t) :: any
  def prev(%T{id: id}, key) do
    Exts.prev(id, key)
  end

  @doc """
  Get the last key in the table, see `ets:last`.
  """
  @spec last(t) :: any
  def last(%T{id: id}) do
    Exts.last(id)
  end

  def keys(self) do
    case select(self, [{{ :'$1', :'$2' }, [], [:'$1'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  def values(self) do
    case select(self, [{{ :'$1', :'$2' }, [], [:'$2'] }]) do
      nil -> []
      s   -> s.values
    end
  end

  @doc """
  Select terms in the table using a match_spec, see `ets:select`.
  """
  @spec select(t, any, Keyword.t) :: [any]
  def select(%T{id: id}, match_spec, options \\ []) do
    Exts.select(id, match_spec, options)
  end

  @doc """
  Select terms in the table using a match_spec, traversing in reverse, see
  `ets:select_reverse`.
  """
  @spec reverse_select(t, any) :: [any]
  def reverse_select(%T{id: id}, match_spec, options \\ []) do
    Exts.reverse_select(id, match_spec, options)
  end

  @doc """
  Match terms from the table with the given pattern, see `ets:match`.
  """
  @spec match(t, any) :: Match.t | nil
  def match(%T{id: id}, pattern, options \\ []) do
    Exts.match(id, pattern, options)
  end

  @doc """
  Get the number of terms in the table.
  """
  @spec count(t) :: non_neg_integer
  def count(%T{id: id}) do
    Exts.count(id)
  end

  @doc """
  Count the number of terms matching the match_spec, see `ets:select_count`.
  """
  @spec count(t, any) :: non_neg_integer
  def count(%T{id: id}, spec) do
    Exts.count(id, spec)
  end

  @doc """
  Fold the table from the left, see `ets:foldl`.
  """
  @spec foldl(t, any, (term, any -> any)) :: any
  def foldl(%T{id: id}, acc, fun) do
    Exts.foldl(id, acc, fun)
  end

  @doc """
  Fold the table from the right, see `ets:foldr`.
  """
  @spec foldr(t, any, (term, any -> any)) :: any
  def foldr(%T{id: id}, acc, fun) do
    Exts.foldr(id, acc, fun)
  end

  @doc false
  def reduce(table, acc, fun) do
    reduce(table, first(table), acc, fun)
  end

  defp reduce(_table, _key, { :halt, acc }, _fun) do
    { :halted, acc }
  end

  defp reduce(table, key, { :suspend, acc }, fun) do
    { :suspended, acc, &reduce(table, key, &1, fun) }
  end

  defp reduce(_table, nil, { :cont, acc }, _fun) do
    { :done, acc }
  end

  defp reduce(table, key, { :cont, acc }, fun) do
    reduce(table, next(table, key), fun.({ key, fetch!(table, key) }, acc), fun)
  end

  defimpl Access do
    def access(table, key) do
      Dict.get(table, key)
    end
  end

  defimpl Enumerable do
    def reduce(table, acc, fun) do
      Exts.Dict.reduce(table, acc, fun)
    end

    def member?(table, { key, value }) do
      { :ok, match?({ :ok, ^value }, Exts.Dict.fetch(table, key)) }
    end

    def member?(_, _) do
      { :ok, false }
    end

    def count(table) do
      { :ok, Exts.Dict.count(table) }
    end
  end
end
