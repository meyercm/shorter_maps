defmodule ShortMaps do
  @default_modifier ?s

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
    names     = String.split(string)
    keys      = Enum.map(names, &strip_pin/1)
    atom_keys = Enum.map(keys, &String.to_atom/1)
    variables = Enum.map(names, &handle_var/1)

    pairs =
      case modifier(modifiers) do
        ?a -> Enum.zip(atom_keys, variables)
        ?s -> Enum.zip(keys, variables)
      end

    {:%{}, line, pairs}
  end

  defmacro sigil_m({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~m sigil"
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
