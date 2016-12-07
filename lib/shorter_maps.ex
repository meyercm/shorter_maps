defmodule ShorterMaps do
  @default_modifier_m ?s
  @default_modifier_M ?a

  @first_letter_uppercase ~r/^\p{Lu}/u

  @doc """
  Returns a string keyed map with the given keys bound to variables of the same
  name.

  A common use of `~m` is when working with JSON, which uses exclusively string
  keys for its maps.  This macro can be used to construct maps from existing
  variables, or to destructure a map into new variables:

      # Construction:
      name = "Chris"
      id = 5
      ~m{name id} # <= %{"name" => "Chris", "id" => 5}

      # Pattern Matching
      ~m{name} = %{"name" => "Bob", "id" => 3}
      name # <= "Bob"

  See ~M (sigil_M) and the README for extended usages.
  """
  defmacro sigil_m(term, modifiers)

  defmacro sigil_m({:<<>>, line, [string]}, modifiers) do
    do_sigil_m(line, String.split(string), modifier(modifiers, @default_modifier_m), __CALLER__)
  end

  defmacro sigil_m({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~m sigil"
  end

  @doc ~S"""
  Returns a map with the given keys bound to variables with the same name.

  This macro sigil is used to reduce boilerplate when writing pattern matches on
  maps that bind variables with the same name as the map keys. For example,
  given a map that looks like this:

      my_map = %{foo: "foo", bar: "bar", baz: "baz"}

  ..the following is very common Elixir code:

      %{foo: foo, bar: bar, baz: baz} = my_map
      foo #=> "foo"

  The `~M` sigil provides a shorter way to do exactly this. It splits the given
  list of words on whitespace (i.e., like the `~w` sigil) and creates a map with
  these keys as the keys and with variables with the same name as values. Using
  this sigil, this code can be reduced to just this:

      ~M(foo bar baz) = my_map
      foo #=> "foo"

  `~M` can be used in regular pattern matches like the ones in the examples
  above but also inside function heads:

      defmodule Test do
        import ShortMaps

        def test(~M(foo)), do: foo
        def test(_),       do: :no_match
      end

      Test.test %{foo: "hello world"} #=> "hello world"
      Test.test %{bar: "hey there!"}  #=> :no_match

  ## Pinning

  Matching using the `~m` sigil has full support for the pin operator:

      bar = "bar"
      ~M(foo ^bar) = %{foo: "foo", bar: "bar"} #=> this is ok, `bar` matches
      foo #=> "foo"
      bar #=> "bar"
      ~M(foo ^bar) = %{foo: "FOO", bar: "bar"} #=> this is still ok
      foo #=> "FOO"; since we didn't pin it, it's now bound to a new value
      bar #=> "bar"
      ~M(foo ^bar) = %{foo: "foo", bar: "BAR"} #=> will raise MatchError

  ## Structs

  For using structs instead of plain maps, the first word must be prefixed with
  '%':

      defmodule Foo do
        defstruct bar: nil
      end

      ~M(%Foo bar) = %Foo{bar: 4711}
      bar #=> 4711

  ## Modifiers

  The `~m` and `~M` sigils support postfix operators for backwards
  compatibility with `ShortMaps`. Atom keys can be specified using the `a`
  modifier, while string keys can be specified with the `s` modifier.

      ~m(blah)a == ~M{blah}
      ~M(blah)s == ~m{blah}

  ## Pitfalls

  Interpolation isn't supported. `~M(#{foo})` will raise an `ArgumentError`
  exception.

  The variables associated with the keys in the map have to exist in the scope
  if the `~M` sigil is used outside a pattern match:

      foo = "foo"
      ~M(foo bar) #=> ** (RuntimeError) undefined function: bar/0
  """
  defmacro sigil_M(term, modifiers)
  defmacro sigil_M({:<<>>, line, [string]}, modifiers) do
    do_sigil_m(line, String.split(string), modifier(modifiers, @default_modifier_M), __CALLER__)
  end
  defmacro sigil_M({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~M sigil"
  end

  defp do_sigil_m(_line, ["%" <> _struct_name | _words], ?s, _caller),
    do: raise(ArgumentError, "structs can only consist of atom keys")
  defp do_sigil_m(_line, ["%" <> struct_name | words], ?a, caller) do
    struct = resolve_module(struct_name, caller)
    pairs = make_pairs(words, ?a)
    quote do: %unquote(struct){unquote_splicing(pairs)}
  end
  defp do_sigil_m(line, words, modifier, _caller) do
    pairs = make_pairs(words, modifier)
    {:%{}, line, pairs}
  end

  defp resolve_module("__MODULE__", caller) do
    {:__MODULE__, [], caller.module}
  end
  defp resolve_module(struct_name, _caller) do
    {:__aliases__, [], [String.to_atom(struct_name)]}
  end

  defp make_pairs(words, modifier) do
    keys      = Enum.map(words, &strip_pin/1)
    variables = Enum.map(words, &handle_var/1)

    ensure_valid_variable_names(keys)

    case modifier do
      ?a -> keys |> Enum.map(&String.to_atom/1) |> Enum.zip(variables)
      ?s -> keys |> Enum.zip(variables)
    end
  end

  defp strip_pin("_" <> name),
    do: name
  defp strip_pin("^" <> name),
    do: name
  defp strip_pin(name),
    do: name

  defp handle_var("^" <> name) do
    {:^, [], [Macro.var(String.to_atom(name), nil)]}
  end
  defp handle_var(name) do
    String.to_atom(name) |> Macro.var(nil)
  end

  defp modifier([], default), do: default
  defp modifier([mod], _default) when mod in 'as', do: mod
  defp modifier(_, _default) do
    raise(ArgumentError, "only these modifiers are supported: s, a")
  end

  defp ensure_valid_variable_names(keys) do
    Enum.each keys, fn k ->
      unless k =~ ~r/\A[a-zA-Z_]\w*\Z/ do
        raise ArgumentError, "invalid variable name: #{k}"
      end
    end
  end
end
