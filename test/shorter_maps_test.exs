defmodule ShorterMapsTest do
  use ExUnit.Case, async: true
  import ShorterMaps

  describe "update syntax" do
    test "works for ~M" do
      old_map = %{hey: "ho"}
      hey = "lets go"
      new_map = ~M{old_map|hey}
      assert new_map == %{hey: "lets go"}
    end

    test "works for ~m" do
      old_map = %{"name" => "chris", "id" => 7}
      name = "bob"
      new_map = ~m{old_map|name}
      assert new_map == %{"name" => "bob", "id" => 7}
    end

    test "many keys works for ~M" do
      old_map = %{a: 1, b: 2, c: 3}
      a = b = c = 7
      new_map = ~M{old_map|a b c}
      assert new_map == %{a: 7, b: 7, c: 7}
    end

    test "many keys works for ~m" do
      old_map = %{"a" => 1, "b" => 2, "c" => 3}
      a = b = c = 7
      new_map = ~m{old_map|a b c}
      assert new_map == %{"a" => 7, "b" => 7, "c" => 7}
    end
  end

  test "uses the bindings from the current environment" do
    foo = 1
    assert ~m(foo)a == %{foo: 1}
    assert ~M(foo) == %{foo: 1}
  end

  test "strings from env" do
    foo = 1
    assert ~m(foo) == %{"foo" => 1}
    assert ~M(foo)s == %{"foo" => 1}
  end

  test "can be used in regular matches" do
    assert ~m(foo)a = %{foo: "bar"}
    assert ~M(bar) = %{bar: "baz"}
    {foo, bar} # this removes the "variable foo is unused" warning
  end

  test "when used in pattern matches, it binds variables in the scope" do
    ~m(foo)a = %{foo: "bar"}
    assert foo == "bar"
    ~M(bar) = %{bar: "baz"}
    assert bar == "baz"
  end

  test "pin syntax in pattern matches will match on same value" do
    foo = "bar"
    assert ~m(^foo)a = %{foo: "bar"}
    assert ~M(^foo) = %{foo: "bar"}
  end

  test "pin syntax in pattern matches will raise if no match" do
    msg = "no match of right hand side value: %{foo: \"baaz\"}"
    assert_raise MatchError, msg, fn ->
      foo = "bar"
      ~m(^foo)a = %{foo: "baaz"}
    end
    assert_raise MatchError, msg, fn ->
      foo = "bar"
      ~M(^foo) = %{foo: "baaz"}
    end
  end

  test "ignore syntax in pattern matches will match" do
    assert ~m(_foo)a = %{foo: "bar"}
    assert ~M(_foo) = %{foo: "bar"}
  end

  test "can be used in function heads for anonymous functions" do
    fun = fn
      ~m(foo) -> foo
      ~M{foo} -> foo <> foo
      _       -> :no_match
    end

    assert fun.(%{foo: "bar"}) == "barbar"
    assert fun.(%{"foo" => "bar"}) == "bar"
    assert fun.(%{baz: "bong"}) == :no_match
  end

  test "can be used in function heads for functions in modules" do
    defmodule FunctionHead do
      def test(~m(foo)), do: foo
      def test(~M(foo)), do: foo <> foo
      def test(_),       do: :no_match
    end

    assert FunctionHead.test(%{"foo" => "bar"}) == "bar"
    assert FunctionHead.test(%{foo: "bar"}) == "barbar"
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

  test "good errors when variables are invalid" do
    code = quote do: ~m(4oo)
    msg = "invalid variable name: 4oo"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end

    code = quote do: ~m($hello!)
    msg = "invalid variable name: $hello!"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end

  defmodule Foo do
    defstruct bar: nil
  end

  test "supports structs" do
    bar = 1
    assert ~m(%Foo bar)a == %Foo{bar: 1}
  end

  test "struct syntax can be used in regular matches" do
    assert ~m(%Foo bar)a = %Foo{bar: "123"}
    bar # this removes the "variable bar is unused" warning
  end

  test "when using structs, fails on non-existing keys" do
    code = quote do: ~m(%Foo bar baaz)a = %Foo{bar: 1}
    msg = ~r/unknown key :baaz for struct ShorterMapsTest.Foo/
    assert_raise CompileError, msg, fn ->
      Code.eval_quoted(code, [], __ENV__)
    end
  end

  test "when using structs, only accepts 'a' modifier" do
    code = quote do
      bar = 5
      ~m(%Foo bar)s
    end
    msg = "structs can only consist of atom keys"
    assert_raise ArgumentError, msg, fn -> Code.eval_quoted(code) end
  end

  defmodule UseInsideStruct do
    defstruct x: nil

    def get_x(~m{%UseInsideStruct x}a), do: x
    def inc_x(~m{%__MODULE__ x}a), do: x+1
  end

  test "can be used with module name within module of the struct" do
    assert UseInsideStruct.get_x(%UseInsideStruct{x: 1}) == 1
  end

  test "can be used with __MODULE__ within module of the struct" do
    assert UseInsideStruct.inc_x(%UseInsideStruct{x: 1}) == 2
  end
end
