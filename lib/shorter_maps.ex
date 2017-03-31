defmodule ShorterMaps do
  @readme Path.join(__DIR__, "../README.md")
  @external_resource @readme
  {:ok, readme_contents} = File.read(@readme)
  @moduledoc "#{readme_contents}"

  @default_modifier_m ?s
  @default_modifier_M ?a

  @doc """
  Returns a string keyed map with the given keys bound to variables of the same
  name.

  A common use of `~m` is when working with JSON, which uses exclusively string
  keys for its maps.  This macro can be used to construct maps from existing
  variables, or to destructure a map into new variables:

      # Construction:
      name = "Chris"
      id = 5
      ~m{name, id} # <= %{"name" => "Chris", "id" => 5}

      # Pattern Matching
      ~m{name} = %{"name" => "Bob", "id" => 3}
      name # <= "Bob"

  See ~M (sigil_M) and the README for extended usages.
  """
  defmacro sigil_m(term, modifiers)

  defmacro sigil_m({:<<>>, line, [string]}, modifiers) do
    do_sigil_m(line, string, modifier(modifiers, @default_modifier_m), __CALLER__)
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

      ~M{foo, bar, baz} = my_map
      foo #=> "foo"

  `~M` can be used in regular pattern matches like the ones in the examples
  above but also inside function heads (note the use of `_bar` in this example):

      defmodule Test do
        import ShortMaps

        def test(~M{foo, _bar}), do: {:with_bar, foo}
        def test(~M{foo}), do: foo
        def test(_),       do: :no_match
      end

      Test.test %{foo: "hello world", bar: :ok} #=> {:with_bar, "hello world"}
      Test.test %{foo: "hello world"} #=> "hello world"
      Test.test %{bar: "hey there!"}  #=> :no_match

  ## Pinning

  Matching using the `~M`/`~m` sigils has full support for the pin operator:

      bar = "bar"
      ~M(foo, ^bar) = %{foo: "foo", bar: "bar"} #=> this is ok, `bar` matches
      foo #=> "foo"
      bar #=> "bar"
      ~M(foo, ^bar) = %{foo: "FOO", bar: "bar"} #=> this is still ok
      foo #=> "FOO"; since we didn't pin it, it's now bound to a new value
      bar #=> "bar"
      ~M(foo, ^bar) = %{foo: "foo", bar: "BAR"} #=> will raise MatchError

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
      ~M(foo, bar) #=> ** (RuntimeError) undefined function: bar/0
  """
  defmacro sigil_M(term, modifiers)
  defmacro sigil_M({:<<>>, line, [string]}, modifiers) do
    do_sigil_m(line, string, modifier(modifiers, @default_modifier_M), __CALLER__)
  end
  defmacro sigil_M({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~M sigil"
  end

  @doc false
  def do_sigil_m(_line, "%" <> _rest, ?s, _caller) do
    raise(ArgumentError, "structs can only consist of atom keys")
  end
  def do_sigil_m(_line, "%" <> rest, ?a, caller) do
    [struct_name|others] = String.split(rest, " ")
    struct = resolve_module(struct_name, caller)
    body = Enum.join(others, " ")
    pairs = make_pairs(body, ?a)
    quote do: %unquote(struct){unquote_splicing(pairs)}
  end
  def do_sigil_m(line, body, modifier, _caller) do
    case String.split(body, "|") do
      [_just_one] ->
        pairs = make_pairs(body, modifier)
        {:%{}, line, pairs}
      [old_map, new_body] ->
        pairs = make_pairs(new_body, modifier)
        {:%{}, line, [{:|, line, [handle_var(old_map), pairs]}]}
      _ -> raise(ArgumentError, "too many | in #{body}")
    end
  end

  @doc false
  def resolve_module("__MODULE__", caller) do
    {:__MODULE__, [], caller.module}
  end
  def resolve_module(struct_name, _caller) do
    {:__aliases__, [], [String.to_atom(struct_name)]}
  end

  @doc false
  def make_pairs(body, modifier) do
    words = String.split(body, ",")
            |> Enum.map(fn w ->
              String.trim(w)
              |> String.split(": ")
            end)
    keys = extract_keys_or_vars(words, :keys) |> strip_prefix
    variables = extract_keys_or_vars(words, :vars) |> handle_var

    ensure_valid_variable_names(keys)

    case modifier do
      ?a -> keys |> Enum.map(&String.to_atom/1) |> Enum.zip(variables)
      ?s -> keys |> Enum.zip(variables)
    end
  end

  @doc false
  def strip_prefix(list) when is_list(list), do: Enum.map(list, &strip_prefix/1)
  def strip_prefix("_" <> name), do: name
  def strip_prefix("^" <> name), do: name
  def strip_prefix(name), do: name

  @doc false
  def handle_var(list) when is_list(list), do: Enum.map(list, &handle_var/1)
  def handle_var("^" <> name), do: {:^, [], [handle_var(name)]}
  def handle_var(name), do: name |> String.to_atom |> Macro.var(nil)

  @doc false
  def extract_keys_or_vars(list, mode, acc \\ [])
  def extract_keys_or_vars([], _mode, acc), do: Enum.reverse(acc)
  def extract_keys_or_vars([[first]|rest], mode, acc) do
    extract_keys_or_vars(rest, mode, [first|acc])
  end
  def extract_keys_or_vars([[key, _var]|rest], :keys = mode, acc) do
    extract_keys_or_vars(rest, mode, [key|acc])
  end
  def extract_keys_or_vars([[_key, var]|rest], :vars = mode, acc) do
    extract_keys_or_vars(rest, mode, [var|acc])
  end

  @doc false
  def modifier([], default), do: default
  def modifier([mod], _default) when mod in 'as', do: mod
  def modifier(_, _default) do
    raise(ArgumentError, "only these modifiers are supported: s, a")
  end

  @doc false
  def ensure_valid_variable_names(keys) do
    Enum.each keys, fn k ->
      unless k =~ ~r/\A[a-zA-Z_]\w*\Z/ do
        raise ArgumentError, "invalid variable name: #{inspect k}"
      end
    end
  end
end
