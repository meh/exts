Code.require_file "test_helper.exs", __DIR__

defmodule TableTest do
  use ExUnit.Case

  test "creation works" do
    t = Exts.Table.new

    assert is_integer t.id
  end

  test "read works" do
    t = Exts.Table.new

    assert t.read(:a) == nil
  end

  test "write works" do
    t = Exts.Table.new

    t.write { :a, 2, 3 }
    assert t.read(:a) == { :a, 2, 3 }
  end

  test "count works" do
    t = Exts.Table.new

    assert t.count == 0

    t.write { :a, 2, 3 }
    t.write { :b, 4, 5 }

    assert t.count == 2
  end

  test "count works with pattern" do
    t = Exts.Table.new

    t.write { :a, 2, 3 }
    t.write { :b, 4, 5 }
    t.write { :c, 3, 6 }

    assert t.count([{{ :_, :'$1', :_ }, [{ :==, { :rem, :'$1', 2 }, 0 }], [{ :const, true }]}]) == 2
  end

  test "iteration works" do
    t = Exts.Table.new

    t.write { :a, 2, 3 }
    t.write { :b, 4, 5 }
    t.write { :c, 3, 6 }

    assert Data.Seq.map(t, fn(x) -> x end) == [{ :a, 2, 3 }, { :b, 4, 5 }, { :c, 3, 6 }]
  end
end
