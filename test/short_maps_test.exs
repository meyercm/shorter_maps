defmodule ShortMapsTest do
  use ExUnit.Case, async: true
  import ShortMaps

  test "uses the bindings from the current environment" do
    foo = 1
    assert ~m(foo)a == %{foo: 1}
  end

  test "can be used in regular matches" do
    assert ~m(foo)a = %{foo: "bar"}
    foo # this removes the "variable foo is unused" warning
  end

  test "when used in pattern matches, it binds variables in the scope" do
    ~m(foo)a = %{foo: "bar"}
    assert foo == "bar"
  end

  test "can be used in function heads for anonymoys functions" do
    fun = fn
      ~m(foo)a -> foo
      _       -> :no_match
    end

    assert fun.(%{foo: "bar"}) == "bar"
    assert fun.(%{baz: "bong"}) == :no_match
  end

  test "can be used in function heads for functions in modules" do
    defmodule FunctionHead do
      def test(~m(foo)a), do: foo
      def test(_),       do: :no_match
    end

    assert FunctionHead.test(%{foo: "bar"}) == "bar"
    assert FunctionHead.test(%{baz: "bong"}) == :no_match
  end

  test "supports atom keys with the 'a' modifier" do
    assert ~m(foo bar)a = %{foo: "foo", bar: "bar"}
    assert {foo, bar} == {"foo", "bar"}
  end

  test "supports string keys with the 's' modifier" do
    assert ~m(foo bar)s = %{"foo" => "hello", "bar" => "world"}
    assert {foo, bar} == {"hello", "world"}
  end

  test "wrong modifiers raise an ArgumentError" do
    code = quote do: ~m(foo)k
    msg = "only these modifiers are supported: s, a"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end

  test "no interpolation is supported" do
    code = quote do: ~m(foo #{bar} baz)a
    msg = "interpolation is not supported with the ~m sigil"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end
end
