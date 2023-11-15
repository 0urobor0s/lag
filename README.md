# LAG (Linear Algebra Graph)

Graphs in the language of linear algebra.

## Installation

In order to use `LAG` in an Elixir project add `LAG` as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:lag, "~> 0.0.1"}
  ]
end
```

If you are using Livebook or IEx, you can instead run:

```elixir
Mix.install([
  {:lag, "~> 0.0.1"}
])
```

## Information

Currently, functions present in module [LAG](https://github.com/0urobor0s/lag/blob/main/lib/lag.ex) and module [LAG.Graph](https://github.com/0urobor0s/lag/blob/main/lib/lag/graph.ex) are supposed to provide the stable API for the library.
However, due to current state of development, the backend module [LAG.NxBackend](https://github.com/0urobor0s/lag/blob/main/lib/lag/nx_backend.ex) is likely to have the most current implementations and trials.
