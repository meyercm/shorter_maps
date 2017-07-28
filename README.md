## ShorterMaps

`~M` sigil for map shorthand. `~M{a} ~> %{a: a}`

`{:shorter_maps, "~> 2.0"},`

### New Features

#### v2.2

 - Allow expressions in mixed mode: `~M{data, len: length(data)}`. Also allows
   nesting the `ShorterMaps` sigil: `~M{worker_id, args: ~M(tty, baud_rate)}`.
   Note that Elixir sigils are terminated as soon as a matching delimiter is
   found, so nested sigils _must_ use different delimiters, and expressions that
   need a particular delimiter (e.g. tuples, lists, function calls) must use a
   different one.

#### v2.1

 - Allow zero arity functions: `~M{node()}` => `%{node: node()}`

#### v2.0

 - _Backward incompatible change_: keys must now be separated with commas.
 - Struct names are still followed by a space: `~M{%Person id, name}`
 - "Mixed mode" allows non-matching keys and variables, e.g.
`~M{key_1, key_2, key_3: other_var}` => `%{key_1: key_1, key_2: key_2, key_3: other_var}`

#### v1.2

 - Added support for map update syntax (`~M{old_map|first_name last_name}`),
instead of writing `%{old_map|first_name: first_name, last_name: last_name}`.
Works with both `~m` and `~M`.

#### v1.1

 - Added support for leading underscore variables (`~M{_id name} = person`),
which allows specifying structural requirements while minimizing compiler warnings
for unused variables.

### Motivation

Code like `%{id: id, name: name, address: address}` occurs with high frequency
in many programming languages.  In Elixir, additional uses occur as we pattern
match to destructure existing maps.

ES6 provided javascript with a shorthand to create maps with keys inferred by
variable names, and allowed destructuring those maps into variables named for
the keys.  `ShorterMaps` provides that functionality to Elixir.

### Syntax Overview => Macro Expansions

`~M` and `~m` can be used to replace maps __anywhere__ in your code. The
`ShorterMaps` sigil syntax operates just like a vanilla elixir map, with two
main differences:

  1) When a variable name stands alone, it is replaced with a key-value pair,
  where the key is the variable name as a string (~m) or an atom (~M). The value
  will be the variable. For example, `~M{name, id: get_free_id()}` expands to
  `%{name: name, id: get_free_id()}`.

  2) Struct names are enclosed in the sigil, rather than outside, e.g.:
  `~M{%StructName key, key2}` === `%StructName{key: key, key2: key2}`. The
  struct name must be followed by a space, and then comma-separated keys.
  Structs can be updated just like maps: `~M{%StructName old_struct|key_to_update}`

Here are the syntactic variants the macro exposes:

* Atom keys: `~M{a, b}` => `%{a: a, b: b}`
* String keys: `~m{a, b}` => `%{"a" => a, "b" => b}`
* Structs: `~M{%Person id, name}` => `%Person{id: id, name: name}`
* Pinned variables: `~M{^a, b}` => `%{a: ^a, b: b}`
* Ignore matching: `~M{_a, b}` => `%{a: _a, b: b}`
* Map update (strings or atoms): `~M{old|a, b, c}` => `%{old|a: a, b: b, c: c}`
* Struct update: `~M{%Person old_struct|name} => %Person{old_struct|name: name}`
* Mixed mode: `~M{a, b: b_alt}` => `%{a: a, b: b_alt}`
* Expressions: `~M{a, b: a + 1}` => `%{a: a, b: a + 1}`
* Zero-arity: `~M{a, b()}` => `%{a: a, b: b()}`
* Modifiers: `~m{blah}a == ~M{blah}` or `~M{blah}s == ~m{blah}`

**Note**: you must `import ShorterMaps` for the sigils to work.

### Example Usage

```elixir
iex> import ShorterMaps
...> name = "Chris"
...> id = 6
...> ~M{name, id}
%{name: "Chris", id: 6}

...> # String Keys:
...> ~m{name, id}
%{"name" => "Chris", "id" => 6}

...> # Structs:
...> defmodule MyStruct do
...>   defstruct [id: nil]
...> end
...> ~M{%MyStruct id}
%MyStruct{id: 6}
```

### Pattern matching:
```elixir
iex> map = %{a: 1, b: 2, c: 3}
...> ~M{a, b} = map
...> a
1

# in function heads:
...> defmodule MyModule do
...>   def my_func(~M{name, _id}), do: {:id_present, name}
...>   def my_func(~M{name}), do: {:no_id, name}
...> end
iex> MyModule.my_func(%{name: "Chris"})
{:no_id, "Chris"}
...> MyModule.my_func(%{name: "Chris", id: 1})
{:id_present, "Chris"}

# Update syntax:
iex> old_map = %{id: 1, name: "Chris"}
...> id = 7
...> ~M{old_map|id} # => %{old_map|id: id}
%{id: 7, name: "Chris"}

# Mixed keys:
iex> old_map = %{id: 1, first_name: "Chris", last_name: "Meyer"}
...> new_id = 6
...> first_name = "C"
...> ~M{old_map|id: new_id, first_name}
%{id: 6, first_name: "C", last_name: "Meyer"}

```

### Credits

ShorterMaps adds additional features to the original project, `ShortMaps`,
located [here][original-repo]. The reasons for the divergence are summarized
[here][divergent-opinion-issue].

[google-groups]: https://groups.google.com/forum/#!topic/elixir-lang-core/NoUo2gqQR3I
[original-repo]: https://github.com/whatyouhide/short_maps
[divergent-opinion-issue]: https://github.com/whatyouhide/short_maps/issues/11
