defmodule ShorterMapsSpec do
  use ESpec
  import ShorterMaps


  describe "map construction" do
    context "~M" do
      example "with one key" do
        key = "value"
        expect ~M{key}|> to(eq %{key: "value"})
      end
      example "with many keys" do
        key_1 = "value_1"
        key_2 = :value_2
        key_3 = 3
        expect ~M{key_1, key_2, key_3} |> to(eq %{key_1: "value_1", key_2: :value_2, key_3: 3})
      end
      example "with mixed keys" do
        key_1 = "val_1"
        key_2_alt = :val2
        expect ~M{key_1, key_2: key_2_alt} |> to(eq %{key_1: "val_1", key_2: :val2})
      end
    end
    context "~m" do
      example "with one key" do
        a_key = :test_value
        expect ~m{a_key} |> to(eq %{"a_key" => :test_value})
      end
      example "with many keys" do
        first_name = "chris"
        last_name = "meyer"
        expect ~m{first_name, last_name} |> to(eq %{"first_name" => "chris", "last_name" => "meyer"})
      end
      example "with mixed keys" do
        key_1 = "value_1"
        key_2_alt = :val_2
        expect ~m{key_1, key_2: key_2_alt} |> to(eq %{"key_1" => "value_1", "key_2" => :val_2})
      end
    end
  end

  describe "inline pattern matches" do
    example "for ~M" do
      ~M{key_1, key_2} = %{key_1: 1, key_2: 2}
      expect key_1 |> to(eq 1)
      expect key_2 |> to(eq 2)
    end
    example "for ~m" do
      ~m{key_1, key_2} = %{"key_1" => 1, "key_2" => 2}
      expect key_1 |> to(eq 1)
      expect key_2 |> to(eq 2)
    end
    example "with mixed_keys" do
      ~M{key_1, key_2: key_2_alt} = %{key_1: :val_1, key_2: "val 2"}
      expect key_1 |> to(eq :val_1)
      expect key_2_alt |> to(eq "val 2")
    end
  end

  describe "function head matches" do
    context "in module" do
      defmodule TestModule do
        def test(~M{key_1, key_2}), do: {:first, key_1, key_2}
        def test(~m{key_1}), do: {:second, key_1}
        def test(_), do: :third
      end

      it "matches in module function heads" do
        expect TestModule.test(%{key_1: 1, key_2: 2}) |> to(eq {:first, 1, 2})
        expect TestModule.test(%{"key_1" => 1}) |> to(eq {:second, 1})
      end
    end

    context "in anonymous functions" do
      it "matches anonymous function heads" do
        fun = fn
            ~m{foo} -> {:first, foo}
            ~M{foo} -> {:second, foo}
            _       -> :no_match
          end

          assert fun.(%{"foo" => "bar"}) == {:first, "bar"}
          assert fun.(%{foo: "barr"}) == {:second, "barr"}
          assert fun.(%{baz: "bong"}) == :no_match
      end
    end
  end

  describe "struct syntax" do
    defmodule TestStruct do
      defstruct [a: nil]
    end
    defmodule TestStruct.Child.GrandChild.Struct do
      defstruct [a: nil]
    end
    example "of construction" do
      a = 5
      expect ~M{%TestStruct a} |> to(eq %TestStruct{a: 5})
    end

    example "of alias resolution" do
      alias TestStruct, as: TS
      a = 3
      expect ~M{%TS a} |> to(eq %TS{a: 3})
    end
    example "of alias resolution" do
      alias TestStruct.Child.GrandChild.{Struct}
      a = 0
      expect ~M{%Struct a} |> to(eq %TestStruct.Child.GrandChild.Struct{a: 0})
    end
    example "of case pattern-match" do
      a = 5
      case %TestStruct{a: 0} do
        ~M{%TestStruct ^a} -> raise("shouldn't have matched")
        ~M{%TestStruct _a} -> :ok
      end
    end


  end

  describe "update syntax" do
    context "~M" do
      example "with one key" do
        initial = %{a: 1, b: 2, c: 3}
        a = 10
        expect ~M{initial|a} |> to(eq %{a: 10, b: 2, c: 3})
      end
      it "allows homogenous keys" do
        initial = %{a: 1, b: 2, c: 3}
        {a, b} = {6, 7}
        expect ~M{initial|a, b} |> to(eq %{a: 6, b: 7, c: 3})
      end
      it "allows mixed keys" do
        initial = %{a: 1, b: 2, c: 3}
        {a, d} = {6, 7}
        expect ~M{initial|a, b: d} |> to(eq %{a: 6, b: 7, c: 3})
      end
    end
    context "~m" do
      example "with one key" do
        initial = %{"a" => 1, "b" => 2, "c" => 3}
        a = 10
        expect ~m{initial|a} |> to(eq %{"a" => 10, "b" => 2, "c" => 3})
      end
      it "allows homogenous keys" do
        initial = %{"a" => 1, "b" => 2, "c" => 3}
        {a, b} = {6, 7}
        expect ~m{initial|a, b} |> to(eq %{"a" => 6, "b" => 7, "c" => 3})
      end
      it "allows mixed keys" do
        initial = %{"a" => 1, "b" => 2, "c" => 3}
        {a, d} = {6, 7}
        expect ~m{initial|a, b: d} |> to(eq %{"a" => 6, "b" => 7, "c" => 3})
      end
    end
  end

  describe "pin syntax" do
    context "~M" do
      example "happy case" do
        matching = 5
        ~M{^matching} = %{matching: 5}
      end
      example "sad case" do
        not_matching = 5
        case %{not_matching: 6} do
          ~M{^not_matching} -> raise("matched when it shouldn't have")
          _ -> :ok
        end
      end
    end
    context "~m" do
      example "happy case" do
        matching = 5
        ~m{^matching} = %{"matching" => 5}
      end
      example "sad case" do
        not_matching = 5
        case %{"not_matching" => 6} do
          ~m{^not_matching} -> raise("matched when it shouldn't have")
          _ -> :ok
        end
      end
    end
  end

  describe "ignore syntax" do
    context "~M" do
      example "happy case" do
        ~M{_ignored, real_val} = %{ignored: 5, real_val: 19}
        expect real_val |> to(eq 19)
      end
      example "sad case" do
        case %{real_val: 19} do
          ~M{_not_present, _real_val} -> raise("matched when it shouldn't have")
          _ -> :ok
        end
      end
    end
    context "~m" do
      example "happy case" do
        ~m{_ignored, real_val} = %{"ignored" => 5, "real_val" => 19}
        expect real_val |> to(eq 19)
      end
      example "sad case" do
        case %{"real_val" => 19} do
          ~m{_not_present, _real_val} -> raise("matched when it shouldn't have")
          _ -> :ok
        end
      end
    end
  end

end
