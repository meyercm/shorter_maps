defmodule ShortMaps.Mixfile do
  use Mix.Project

  @version "2.0.0"
  @repo_url "https://github.com/meyercm/shorter_maps"

  def project do
    [
      app: :shorter_maps,
      version: @version,
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      # Hex
      package: hex_package(),
      description: "~M sigil for map shorthand. `~M{id name} ~> %{id: id, name: name}`",
      # Docs
      name: "ShorterMaps",
      # Testing
      preferred_cli_env: [espec: :test],
    ]
  end

  def application do
    [applications: []]
  end

  defp hex_package do
    [maintainers: ["Chris Meyer"],
     licenses: ["MIT"],
     links: %{"GitHub" => @repo_url}]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev},
      {:espec, "~> 1.2", only: [:dev, :test]},
    ]
  end
end
