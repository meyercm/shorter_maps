defmodule ShortMaps do
  defmacro sigil_m({:<<>>, line, [string]}, modifiers) do
    keys      = String.split(string)
    atom_keys = Enum.map(keys, &String.to_atom/1)
    variables = Enum.map(atom_keys, &Macro.var(&1, nil))

    pairs =
      case modifier(modifiers) do
        ?a -> Enum.zip(atom_keys, variables)
        ?s -> Enum.zip(keys, variables)
      end

    {:%{}, line, pairs}
  end

  defmacro sigil_m({:<<>>, line, _}, _modifiers) do
    raise ArgumentError, "interpolation is not supported with the ~m sigil"
  end

  defp modifier([]),
    do: ?a
  defp modifier([mod]) when mod in 'as',
    do: mod
  defp modifier(_),
    do: raise(ArgumentError, "only these modifiers are supported: s, a")
end
