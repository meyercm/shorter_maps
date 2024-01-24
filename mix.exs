defmodule ShorterMaps.Mixfile do
  use Mix.Project

  @version "2.2.5"
  @repo_url "https://github.com/meyercm/shorter_maps"

  def project do
    [
      app: :shorter_maps,
      version: @version,
      elixir: "~> 1.0",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Hex
      package: hex_package(),
      description: "~M sigil for map shorthand. `~M{id, name} ~> %{id: id, name: name}`",
      # Docs
      name: "ShorterMaps"
    ]
  end

  def application do
    [applications: []]
  end

  defp hex_package do
    [maintainers: ["Chris Meyer"], licenses: ["MIT"], links: %{"GitHub" => @repo_url}]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end
end
