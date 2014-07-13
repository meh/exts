#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Select do
  defstruct values: [], continuation: nil, reverse: false

  alias Exts.Select, as: Select
  alias Exts.Selection, as: Selection

  def new(value, reverse \\ false) do
    case value do
      :'$end_of_table' -> nil
      []               -> nil
      { [], _ }        -> nil

      { values, continuation } ->
        %Select{values: values, continuation: continuation, reverse: reverse}

      [_ | _] ->
        %Select{values: value, reverse: reverse}
    end
  end

  defimpl Selection do
    def next(%Select{continuation: nil}) do
      nil
    end

    def next(%Select{reverse: false, continuation: continuation}) do
      Select.new(:ets.select(continuation))
    end

    def next(%Select{reverse: true, continuation: continuation}) do
      Select.new(:ets.select_reverse(continuation), true)
    end

    def values(%Select{values: values}) do
      values
    end
  end
end
