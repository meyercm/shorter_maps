defmodule ShortMaps.Mixfile do
  use Mix.Project

  @version "0.1.1"
  @repo_url "https://github.com/whatyouhide/short_maps"

  def project do
    [app: :shorter_maps,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     # Hex
     package: hex_package,
     description: "Implementation of a ~m sigil for ES6-like maps in Elixir",
     # Docs
     name: "ShortMaps",
     docs: [source_ref: "v#{@version}", main: "ShortMaps", source_url: @repo_url]]
  end

  def application do
    [applications: []]
  end

  defp hex_package do
    [maintainers: ["Andrea Leopardi"],
     licenses: ["MIT"],
     links: %{"GitHub" => @repo_url}]
  end

  defp deps do
    [{:earmark, ">= 0.0.0", only: :docs},
     {:ex_doc, ">= 0.0.0", only: :docs}]
  end
end
