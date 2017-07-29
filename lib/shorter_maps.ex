defmodule ShorterMaps do
  @readme Path.join(__DIR__, "../README.md")
  @external_resource @readme
  {:ok, readme_contents} = File.read(@readme)
  @moduledoc "#{readme_contents}"

  @default_modifier_m ?s
  @default_modifier_M ?a

  @doc """
  Expands to a string keyed map where the keys are a string containing the
  variable names, e.g. `~m{name}` expands to `%{"name" => name}`.

  Some common uses of `~m` are when working with JSON and Regex captures, which
  use exclusively string keys in their maps.

      # JSON example:
      # Here, `~m{name, age}` expands to `%{"name" => name, "age" => age}`
      iex> ~m{name, age} = Poison.decode!("{\"name\": \"Chris\",\"age\": \"old\"}")
      %{"name" => "Chris", "age" => "old"}
      ...> name
      "Chris"
      ...> age
      "old"


  See the README for extended syntax and usage.
  """
  defmacro sigil_m(term, modifiers)

  defmacro sigil_m({:<<>>, _line, [string]}, modifiers) do
    do_sigil_m(string, modifier(modifiers, @default_modifier_m))
  end

  defmacro sigil_m({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~m sigil"
  end

  @doc ~S"""
  Expands an atom-keyed map with the given keys bound to variables with the same
  name.

  Because `~M` operates on atoms, it is compatible with Structs.

  ## Examples:

      # Map construction:
      iex> tty = "/dev/ttyUSB0"
      ...> baud = 19200
      ...> device = ~M{tty, baud}
      %{baud: 19200, tty: "/dev/ttyUSB0"}

      # Map Update:
      ...> baud = 115200
      ...> %{device|baud}
      %{baud: 115200, tty: "/dev/ttyUSB0"}

      # Struct Construction
      iex> id = 100
      ...> ~M{%Person id}
      %Person{id: 100, other_key: :default_val}

  """
  defmacro sigil_M(term, modifiers)
  defmacro sigil_M({:<<>>, _line, [string]}, modifiers) do
    do_sigil_m(string, modifier(modifiers, @default_modifier_M))
  end
  defmacro sigil_M({:<<>>, _, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~M sigil"
  end

  @doc false
  def do_sigil_m("%" <> _rest, ?s) do
    raise(ArgumentError, "structs can only consist of atom keys")
  end
  def do_sigil_m(raw_string, modifier) do
    with {:ok, struct_name, rest} <- get_struct(raw_string),
         {:ok, old_map, rest} <- get_old_map(rest),
         {:ok, keys_and_values} <- expand_variables(rest, modifier) do
      final_string = "%#{struct_name}{#{old_map}#{keys_and_values}}"
      #IO.puts("#{raw_string} => #{final_string}") # For debugging expansions gone wrong.
      Code.string_to_quoted!(final_string, file: __ENV__.file, line: __ENV__.line)
    else
      {:error, step, reason} ->
        raise(ArgumentError, "ShorterMaps parse error in step: #{step}, reason: #{reason}")
    end
  end

  @doc false
  # expecting something like: '%StructName key1, key2' -or- '%StructName oldmap|key1, key2'
  # returns {:ok, old_map, keys_and_vars} | {:ok, "", keys_and_vars}
  def get_struct("%" <> rest) do
    [struct_name|others] = String.split(rest, " ")
    body = Enum.join(others, " ")
    {:ok, struct_name, body}
  end
  def get_struct(no_struct), do: {:ok, "", no_struct}

  @re_prefix "[_^]"
  @re_varname ~S"[a-zA-Z_]\w*" # use ~S to get a real \
  @doc false
  # expecting something like "old_map|key1, key2" -or- "key1, key2"
  # returns {:ok, "#{old_map}|", keys_and_vars} | {:ok, "", keys_and_vars}
  def get_old_map(string) do
    cond do
      string =~ ~r/\A\s*#{@re_varname}\s*\|/ -> # make sure this is a map update pipe
        [old_map|rest] = String.split(string, "|")
        new_body = Enum.join(rest, "|") # put back together unintentionally split things
        {:ok, "#{old_map}|", new_body}
      true ->
        {:ok, "", string}
    end
  end

  @doc false

  # This works simply:  split the whole string on commas. check each entry to
  # see if it looks like a variable (with or without prefix) or zero-arity
  # function.  If it is, replace it with the expanded version.  Otherwise, leave
  # it alone. Once all the pieces are processed, glue it back together with
  # commas.

  def expand_variables(string, modifier) do
    result = string
             |> String.split(",")
             |> Enum.map(fn s ->
               cond do
                 s =~ ~r/\A\s*#{@re_prefix}?#{@re_varname}(\(\s*\))?\s*\Z/ ->
                   s
                   |> String.trim
                   |> expand_variable(modifier)
                 true -> s
               end
             end)
             |> Enum.join(",")
     {:ok, result}
  end

  @doc false
  def expand_variable(var, ?s) do
    "\"#{fix_key(var)}\" => #{var}"
  end
  def expand_variable(var, ?a) do
    "#{fix_key(var)}: #{var}"
  end

  @doc false
  def fix_key("_" <> name), do: name
  def fix_key("^" <> name), do: name
  def fix_key(name) do
    String.replace_suffix(name, "()", "")
  end

  @doc false
  def modifier([], default), do: default
  def modifier([mod], _default) when mod in 'as', do: mod
  def modifier(_, _default) do
    raise(ArgumentError, "only these modifiers are supported: s, a")
  end

end
