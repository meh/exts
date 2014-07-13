defmodule Exts.Match do
  defstruct values: [], continuation: nil, whole: false

  alias Exts.Match, as: Match
  alias Exts.Selection, as: Selection

  def new(value, whole \\ false) do
    case value do
      :'$end_of_table' -> nil
      []               -> nil
      { [], _ }        -> nil

      { values, continuation } ->
        %Match{values: values, continuation: continuation, whole: whole}

      [_ | _] ->
        %Match{values: value, whole: whole}
    end
  end

  defimpl Selection do
    def next(%Match{continuation: nil}) do
      nil
    end

    def next(%Match{whole: true, continuation: continuation}) do
      Match.new(:ets.match_object(continuation))
    end

    def next(%Match{whole: false, continuation: continuation}) do
      Match.new(:ets.match(continuation))
    end

    def values(%Match{values: values}) do
      values
    end
  end
end
