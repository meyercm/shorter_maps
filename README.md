# ShortMaps

Implementation of a `~m` sigil for ES6-like maps in Elixir.

## Rationale

ShortMaps is the result of a
[discussion in the Elixir mailing list][google-groups]. The topic of the
discussion was the introduction of a syntax for maps similar to ES6 map syntax:

```elixir
foo = 1
bar = 2

%{foo, bar} == %{foo: foo, bar: bar}
#=> true
```

The discussion on pros and cons went on for a while until @josevalim came up
with a better solution (like he always does): using sigils.

```elixir
foo = 1
bar = 2

~m(foo bar)a == %{foo: foo, bar: bar}
#=> true
```

Sigils allow to:

- be more explicit and declarative
- use both atom and string keys (using modifiers in the sigil)

This library is an attempt to implement this so that you can try it out.

## Examples

```elixir
my_map = %{foo: 1, bar: 2, baz: 3}

~m(foo bar baz)a = my_map
foo #=> 1
```

```elixir
name = "Meg"

# String keys by default (or with the 's' modifier)
~m(name) #=> %{"name" => "Meg"}
# Atom keys with the 'a' modifier
~m(name)a #=> %{name: "Meg"}
```

## LICENSE

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>


[google-groups]: https://groups.google.com/forum/#!topic/elixir-lang-core/NoUo2gqQR3I
