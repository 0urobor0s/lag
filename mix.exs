defmodule LAG.MixProject do
  use Mix.Project

  @source_url "https://github.com/0urobor0s/lag"
  @version "0.0.1"

  def project do
    [
      app: :lag,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "LAG (Linear Algebra Graph)",
      package: package(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "LAG",
      source_url: @source_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [default_backend: {LAG.NxBackend, []}]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.6"},
      # {:nx, github: "elixir-nx/nx", sparse: "nx", override: true, branch: "v0.6"},
      {:exla, "~> 0.6", optional: true},
      {:benchee, "~> 1.0", only: :dev}
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
