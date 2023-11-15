defmodule LAG.GraphFixtures do
  @moduledoc """
  This module defines test helpers for creating
  graphs via the `LAG.Graph` struct.
  """

  @doc """
  Generate a graph.
  """
  def graph_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      vertices: ["a", "b", "c", "d", "e", "f", "g", "h"],
      edges: [
        ["a", "b"],
        ["b", "c"],
        ["b", "e"],
        ["b", "f"],
        ["c", "d"],
        ["c", "g"],
        ["d", "c"],
        ["d", "h"],
        ["e", "f"],
        ["f", "g"],
        ["g", "f"],
        ["g", "h"],
        ["h", "h"]
      ],
      opts: []
    })
    |> then(&LAG.Graph.new(&1.vertices, &1.edges, &1.opts))
  end
end
