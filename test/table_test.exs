Code.require_file "../test_helper.exs", __FILE__

defmodule TableTest do
  use ExUnit.Case

  test "creation works" do
    t = Exts.Table.new

    assert is_integer t.id
  end
end
