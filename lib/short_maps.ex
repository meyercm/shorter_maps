defmodule ShortMaps do
  @default_modifier ?s

  @first_letter_uppercase ~r/^\p{Lu}/u

  @doc ~S"""
  Returns a map with the given keys bound to variables with the same name.

  This macro sigil is used to reduce boilerplate when writing pattern matches on
  maps that bind variables with the same name as the map keys. For example, this
  is very common Elixir code:

      my_map = %{foo: "foo", bar: "bar", baz: "baz"}

      %{foo: foo, bar: bar, baz: baz} = my_map
      foo #=> "foo"

  The `~m` sigil provides a shorter way to do exactly this. It splits the given
  list of words on whitespace (i.e., like the `~w` sigil) and creates a map with
  these keys as the keys and with variables with the same name as values. Using
  this sigil, this code can be reduced to just this:

      ~m(foo bar baz)a = my_map
      foo #=> "foo"

  `~m` can be used in regular pattern matches like the ones in the examples
  above but also inside function heads:

      defmodule Test do
        import ShortMaps

        def test(~m(foo)a), do: foo
        def test(_),       do: :no_match
      end

      Test.test %{foo: "hello world"} #=> "hello world"
      Test.test %{bar: "hey there!"}  #=> :no_match

  ## Modifiers

  The `~m` sigil supports both maps with atom keys as well as string keys. Atom
  keys can be specified using the `a` modifier, while string keys can be
  specified with the `s` modifier (which is the default).

      ~m(my_key)s = %{"my_key" => "my value"}
      my_key #=> "my value"

  ## Pitfalls

  Interpolation isn't supported. `~m(#{foo})` will raise an `ArgumentError`
  exception.

  The variables associated with the keys in the map have to exist in the scope
  if the `~m` sigil is used outside a pattern match:

      foo = "foo"
      ~m(foo bar) #=> ** (RuntimeError) undefined function: bar/0

  ## Discussion

  For more information on this sigil and the discussion that lead to it, visit
  [this
  topic](https://groups.google.com/forum/#!topic/elixir-lang-core/NoUo2gqQR3I)
  in the Elixir mailing list.

  """
  defmacro sigil_m(term, modifiers)

  defmacro sigil_m({:<<>>, line, [string]}, modifiers) do
    do_sigil_m(line, String.split(string), modifier(modifiers))
  end

  defmacro sigil_m({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~m sigil"
  end


  defp do_sigil_m(_line, ["%" <> _struct_name | _words], ?s),
    do: raise(ArgumentError, "structs can only consist of atom keys")
  defp do_sigil_m(line, ["%" <> struct_name | words], ?a) do
    struct = String.to_atom("Elixir." <> struct_name)
    pairs = make_pairs(words, ?a)
    quote do: %__MODULE__.unquote(struct){unquote_splicing(pairs)}
  end

  defp do_sigil_m(line, words, modifier) do
    pairs = make_pairs(words, modifier)
    {:%{}, line, pairs}
  end

  defp make_pairs(words, modifier) do
    keys      = Enum.map(words, &strip_pin/1)
    variables = Enum.map(words, &handle_var/1)

    case modifier do
      ?a -> keys |> Enum.map(&String.to_atom/1) |> Enum.zip(variables)
      ?s -> keys |> Enum.zip(variables)
    end
  end

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

  defp modifier([]),
    do: @default_modifier
  defp modifier([mod]) when mod in 'as',
    do: mod
  defp modifier(_),
    do: raise(ArgumentError, "only these modifiers are supported: s, a")
end
