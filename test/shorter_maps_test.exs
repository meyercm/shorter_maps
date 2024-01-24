defmodule ShorterMapsTest do
  alias ExUnit.TestModule
  use ExUnit.Case
  import ShorterMaps

  def eval(quoted_code), do: fn -> Code.eval_quoted(quoted_code) end

  describe "map construction ~M" do
    test "with one key" do
      key = "value"
      assert %{key: "value"} = ~M{key}
    end

    test "with many keys" do
      key_1 = "value_1"
      key_2 = :value_2
      key_3 = 3
      assert %{key_1: "value_1", key_2: :value_2, key_3: 3} = ~M{key_1, key_2, key_3}
    end

    test "with mixed keys" do
      key_1 = "val_1"
      key_2_alt = :val2
      assert %{key_1: "val_1", key_2: :val2} = ~M{key_1, key_2: key_2_alt}
    end

    test "raises on invalid varnames" do
      quoted = quote do: ~M{4asdf}
      assert_raise(SyntaxError, eval(quoted))
    end
  end

  describe "map construction ~m" do
    test "with one key" do
      a_key = :test_value
      assert %{"a_key" => :test_value} = ~m{a_key}
    end

    test "with many keys" do
      first_name = "chris"
      last_name = "meyer"

      assert %{"first_name" => "chris", "last_name" => "meyer"} = ~m{first_name, last_name}
    end

    test "with mixed keys" do
      key_1 = "value_1"
      key_2_alt = :val_2

      assert %{"key_1" => "value_1", "key_2" => :val_2} = ~m{key_1, "key_2" => key_2_alt}
    end

    test "raises on invalid varnames" do
      code = quote do: ~m{4asdf}
      assert_raise(SyntaxError, eval(code))
    end
  end

  describe "inline pattern matches" do
    test "for ~M" do
      ~M{key_1, key_2} = %{key_1: 1, key_2: 2}
      assert 1 = key_1
      assert 2 = key_2
    end

    test "for ~m" do
      ~m{key_1, key_2} = %{"key_1" => 1, "key_2" => 2}
      assert 1 = key_1
      assert 2 = key_2
    end

    test "with mixed_keys" do
      ~M{key_1, key_2: key_2_alt} = %{key_1: :val_1, key_2: "val 2"}
      assert :val_1 = key_1
      assert "val 2" = key_2_alt
    end

    test "fails to match when there is no match" do
      code = quote do: ~M{key_1} = %{key_2: 1}
      assert_raise(MatchError, eval(code))
    end
  end

  describe "function head matches in module" do
    defmodule TestModule do
      def test(~M{key_1, key_2}), do: {:first, key_1, key_2}
      def test(~m{key_1}), do: {:second, key_1}
      def test(_), do: :third
    end

    test "matches in module function heads" do
      assert {:first, 1, 2} = TestModule.test(%{key_1: 1, key_2: 2})
      assert {:second, 1} = TestModule.test(%{"key_1" => 1})
    end
  end

  describe "function head matches in anonymous functions" do
    test "matches anonymous function heads" do
      fun = fn
        ~m{foo} -> {:first, foo}
        ~M{foo} -> {:second, foo}
        _ -> :no_match
      end

      assert fun.(%{"foo" => "bar"}) == {:first, "bar"}
      assert fun.(%{foo: "barr"}) == {:second, "barr"}
      assert fun.(%{baz: "bong"}) == :no_match
    end
  end

  describe "struct syntax" do
    defmodule TestStruct do
      defstruct a: nil
    end

    defmodule TestStruct.Child.GrandChild.Struct do
      defstruct a: nil
    end

    test "of construction" do
      a = 5
      assert %TestStruct{a: 5} = ~M{%TestStruct a}
    end

    test "of alias resolution" do
      alias TestStruct, as: TS
      a = 3
      assert %TS{a: 3} = ~M{%TS a}
    end

    test "of child alias resolution" do
      alias TestStruct.Child.GrandChild.{Struct}
      a = 0
      assert %TestStruct.Child.GrandChild.Struct{a: 0} = ~M{%Struct a}
    end

    test "of case pattern-match" do
      a = 5

      case %TestStruct{a: 0} do
        ~M{%TestStruct ^a} -> raise("shouldn't have matched")
        ~M{%TestStruct _a} -> :ok
      end
    end

    # TODO: figure out why this test doesn't work.  A manual test in a compiled
    # .ex does raise a KeyError, but not this one:
    # test"raises on invalid keys" do
    #   code = quote do: b = 5; ~m{%TestStruct b}
    #   expect eval(code) |> to(raise_exception(KeyError))
    # end

    test "works for a local module" do
      defmodule InnerTestStruct do
        defstruct a: nil

        def test() do
          a = 5
          ~M{%__MODULE__ a}
        end
      end

      # need to use the :__struct__ version due to compile order?
      assert %{__struct__: InnerTestStruct, a: 5} = InnerTestStruct.test()
    end
  end

  describe "update syntax ~M" do
    test "with one key" do
      initial = %{a: 1, b: 2, c: 3}
      a = 10
      assert %{a: 10, b: 2, c: 3} = ~M{initial|a}
    end

    test "allows homogenous keys" do
      initial = %{a: 1, b: 2, c: 3}
      {a, b} = {6, 7}
      assert %{a: 6, b: 7, c: 3} = ~M{initial|a, b}
    end

    test "allows mixed keys" do
      initial = %{a: 1, b: 2, c: 3}
      {a, d} = {6, 7}
      assert %{a: 6, b: 7, c: 3} = ~M{initial|a, b: d}
    end

    test "can update a struct" do
      old_struct = %Range{first: 1, last: 2, step: 1}
      last = 3
      %Range{first: 1, last: 3} = ~M{old_struct|last}
    end

    defmodule TestStructForUpdate do
      defstruct a: 1, b: 2, c: 3
    end

    test "of multiple key update" do
      old_struct = %TestStructForUpdate{a: 10, b: 20, c: 30}
      a = 3
      b = 4
      assert %TestStructForUpdate{a: 3, b: 4, c: 30} = ~M{old_struct|a, b}
    end
  end

  describe "update syntax ~m" do
    test "with one key" do
      initial = %{"a" => 1, "b" => 2, "c" => 3}
      a = 10
      assert %{"a" => 10, "b" => 2, "c" => 3} = ~m{initial|a}
    end

    test "allows homogenous keys" do
      initial = %{"a" => 1, "b" => 2, "c" => 3}
      {a, b} = {6, 7}
      assert %{"a" => 6, "b" => 7, "c" => 3} = ~m{initial|a, b}
    end

    test "allows mixed keys" do
      initial = %{"a" => 1, "b" => 2, "c" => 3}
      {a, d} = {6, 7}
      assert %{"a" => 6, "b" => 7, "c" => 3} = ~m{initial|a, "b" => d}
    end
  end

  describe "pin syntax ~M" do
    test "happy case" do
      matching = 5
      ~M{^matching} = %{matching: 5}
    end

    test "sad case" do
      not_matching = 5

      case %{not_matching: 6} do
        ~M{^not_matching} -> raise("matched when test shouldn't have")
        _ -> :ok
      end
    end
  end

  describe "pin syntax ~m" do
    test "happy case" do
      matching = 5
      ~m{^matching} = %{"matching" => 5}
    end

    test "sad case" do
      not_matching = 5

      case %{"not_matching" => 6} do
        ~m{^not_matching} -> raise("matched when test shouldn't have")
        _ -> :ok
      end
    end
  end

  describe "ignore syntax ~M" do
    test "happy case" do
      ~M{_ignored, real_val} = %{ignored: 5, real_val: 19}
      assert 19 = real_val
    end

    test "sad case" do
      case %{real_val: 19} do
        ~M{_not_present, _real_val} -> raise("matched when test shouldn't have")
        _ -> :ok
      end
    end
  end

  describe "ignore syntax ~m" do
    test "happy case" do
      ~m{_ignored, real_val} = %{"ignored" => 5, "real_val" => 19}
      assert 19 = real_val
    end

    test "sad case" do
      case %{"real_val" => 19} do
        ~m{_not_present, _real_val} -> raise("matched when test shouldn't have")
        _ -> :ok
      end
    end
  end

  def blah do
    :bleh
  end

  describe "zero-arity" do
    test "Kernel function" do
      assert %{node: node()} == ~M{node()}
    end

    test "local function" do
      assert %{blah: :bleh} == ~M{blah()}
    end

    test "calls the function at run-time" do
      mypid = self()
      assert %{self: ^mypid} = ~M{self()}
    end
  end

  describe "nested sigils" do
    test "two levels" do
      [a, b, c] = [1, 2, 3]
      assert %{a: ^a, b: %{b: ^b, c: ^c}} = ~M{a, b: ~M(b, c)}
    end
  end

  describe "literals" do
    test "adding" do
      a = 1
      assert %{a: ^a, b: 3} = ~M{a, b: a+2}
    end

    test "function call" do
      a = []
      %{a: [], len: 0} = ~M{a, len: length(a)}
    end

    test "embedded shortermap" do
      a = 1
      b = 2
      assert %{a: ^a, b: %{b: ^b}} = ~M{a, b: ~M(b)}
    end

    test "embedded commas" do
      a = 1
      assert %{a: ^a, b: <<1, 2, 3>>} = ~M{a, b: <<1, 2, 3>>}
    end

    test "function call with arguments" do
      a = :hey
      assert %{a: ^a, b: 3} = ~M{a, b: div(10, 3)}
    end

    test "pipeline" do
      a = :hey
      assert %{a: ^a, b: "hey"} = ~M{a, b: a |> Atom.to_string}
    end

    test "string keys" do
      a = "blah"
      b = "bleh"

      assert %{"a" => ^a, "b" => %{"a" => ^a, "b" => ^b}} = ~m{a, "b" => ~m(a, b)}
    end

    test "string interpolation" do
      a = "blah"
      b = "bleh"
      assert %{a: ^a, b: "blehbleh, c"} = ~M(a, b: "#{b <> b}, c")
    end
  end

  describe "regressions and bugfixes" do
    test "of mixed-mode parse error" do
      a = 5
      assert %{key: [1, ^a, 2]} = ~M{key: [1, a, 2]}
    end

    test "of import shadowing" do
      defmodule Test do
        import ShorterMaps

        def test do
          get_struct(:a)
          get_old_map(:a)
          expand_variables(:a, :b)
          expand_variable(:a, :b)
          identify_entries(:a, :b, :c)
          check_entry(:a, :b)
          expand_variable(:a, :b)
          fix_key(:a)
          modifier(:a, :b)
          do_sigil_m(:a, :b)
        end

        def get_struct(a), do: ~M{a}
        def get_old_map(a), do: a
        def expand_variables(a, b), do: {a, b}
        def expand_variable(a, b), do: {a, b}
        def identify_entries(a, b, c), do: {a, b, c}
        def check_entry(a, b), do: {a, b}
        def fix_key(a), do: a
        def modifier(a, b), do: {a, b}
        def do_sigil_m(a, b), do: {a, b}
      end
    end

    test "of varname variations" do
      a? = 1
      assert %{a?: ^a?} = ~M{a?}
      a5 = 2
      assert %{a5: ^a5} = ~M{a5}
      a! = 3
      assert %{a!: ^a!} = ~M{a!}
    end
  end
end
