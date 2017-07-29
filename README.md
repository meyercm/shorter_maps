## ShorterMaps

`~M` sigil for map shorthand. `~M{a} ~> %{a: a}`

### Getting started

1) Add `{:shorter_maps, "~> 2.0"},` to your mix deps
2) Add `import ShorterMaps` to the top of your module
3) DRY up your maps and structs with `~M` and `~m`. Instead of `%{name: name}`
   use `~M{name}`, and for `%{"name" => name}` use `~M{name}`. When the key and
   the variable don't match, don't fret: `~M{name, id: current_id}` expands
   to `%{name: name, id: current_id}`.

### Motivation

Code like `%{id: id, name: name, address: address}` occurs with high frequency
in many programming languages.  In Elixir, additional uses occur as we pattern
match to destructure existing maps.

ES6 provided javascript with a shorthand to create maps with keys inferred by
variable names, and allowed destructuring those maps into variables named for
the keys.  `ShorterMaps` provides that functionality to Elixir.

### Syntax:

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

### Examples

```elixir
iex> import ShorterMaps
...> name = "Chris"
...> id = 6
...> ~M{name, id}
%{name: "Chris", id: 6}

# It's ok to mix in other expressions:
...> ~M{name, id: id + 200}
%{name: "Chris", id: 206}

# or even nest the sigil (note the change in delimiters to paren):
...> ~M{name, id, extra_copy: ~M(name, id)}
%{name: "Chris", id: 6, extra_copy: %{name: "Chris", id: 6}}

# We can use String keys:
...> ~m{name, id}
%{"name" => "Chris", "id" => 6}

# And we can update existing maps:
...> map_1 = %{name: "Bob", id: 9}
...> ~M{map_1|name}
%{name: "Chris", id: 9}

# Struct syntax is a little funky:
...> defmodule MyStruct do
...>   defstruct [id: nil, name: :default]
...> end
...> ~M{%MyStruct id}
%MyStruct{id: 6, name: :default}

# Structs can be updated too:
...> initial_struct = %MyStruct{name: "Chris", id: :unknown}
...> ~M{%MyStruct initial_struct|id}
%MyStruct{name: "Chris", id: 6}

# Because the expansion happens at compile time, they can be used __anywhere__:

# in function heads:
...> defmodule MyModule do
...>   def my_func(~M{name, _id}), do: {:id_present, name}
...>   def my_func(~M{name}), do: {:no_id, name}
...> end

# in pattern matches:
...> ~M{age, model} = %{age: -30, model: "Delorean", manufacturer: "AMC"}
...> age
-55

```

### Credits

ShorterMaps adds additional features to the original project, `ShortMaps`,
located [here][original-repo]. The reasons for the divergence are summarized
[here][divergent-opinion-issue].

[original-repo]: https://github.com/whatyouhide/short_maps
[divergent-opinion-issue]: https://github.com/whatyouhide/short_maps/issues/11

### Quick Reference:

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
