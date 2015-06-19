defmodule ShortMaps.Mixfile do
  use Mix.Project

  @version "1.0.0-alpha"

  def project do
    [app: :short_maps,
     version: @version,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: []]
  end

  defp deps do
    []
  end
end
