defmodule LAG.MixProject do
  use Mix.Project

  def project do
    [
      app: :lag,
      version: "0.0.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
end
