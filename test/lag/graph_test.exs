defmodule LAG.GraphTest do
  use ExUnit.Case
  doctest LAG.Graph

  describe "new/3" do
    test "undirected graph" do
      vertices = ["a", "b", "c", "d", "e", "f", "g", "h"]

      edges = [
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
        ["g", "h"]
      ]

      g = LAG.Graph.new(vertices, edges, type: :undirected)

      adjacency_matrix =
        Nx.tensor([
          [0, 1, 0, 0, 0, 0, 0, 0],
          [1, 0, 1, 0, 1, 1, 0, 0],
          [0, 1, 0, 1, 0, 0, 1, 0],
          [0, 0, 1, 0, 0, 0, 0, 1],
          [0, 1, 0, 0, 0, 1, 0, 0],
          [0, 1, 0, 0, 1, 0, 1, 0],
          [0, 0, 1, 0, 0, 1, 0, 1],
          [0, 0, 0, 1, 0, 0, 1, 0]
        ])

      index = %{
        0 => "a",
        1 => "b",
        2 => "c",
        3 => "d",
        4 => "e",
        5 => "f",
        6 => "g",
        7 => "h"
      }

      map = %{
        "a" => 0,
        "b" => 1,
        "c" => 2,
        "d" => 3,
        "e" => 4,
        "f" => 5,
        "g" => 6,
        "h" => 7
      }

      assert g.vertices.index == index
      assert g.vertices.map == map
      assert Nx.equal(g.adjacency_matrix, adjacency_matrix) |> Nx.all() |> Nx.to_number()
    end

    test "directed graph" do
      vertices = ["a", "b", "c", "d", "e", "f", "g", "h"]

      edges = [
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
        ["g", "h"]
      ]

      g = LAG.Graph.new(vertices, edges, type: :directed)

      adjacency_matrix =
        Nx.tensor([
          [0, 1, 0, 0, 0, 0, 0, 0],
          [0, 0, 1, 0, 1, 1, 0, 0],
          [0, 0, 0, 1, 0, 0, 1, 0],
          [0, 0, 1, 0, 0, 0, 0, 1],
          [0, 0, 0, 0, 0, 1, 0, 0],
          [0, 0, 0, 0, 0, 0, 1, 0],
          [0, 0, 0, 0, 0, 1, 0, 1],
          [0, 0, 0, 0, 0, 0, 0, 0]
        ])

      index = %{
        0 => "a",
        1 => "b",
        2 => "c",
        3 => "d",
        4 => "e",
        5 => "f",
        6 => "g",
        7 => "h"
      }

      map = %{
        "a" => 0,
        "b" => 1,
        "c" => 2,
        "d" => 3,
        "e" => 4,
        "f" => 5,
        "g" => 6,
        "h" => 7
      }

      assert g.vertices.index == index
      assert g.vertices.map == map
      assert Nx.equal(g.adjacency_matrix, adjacency_matrix) |> Nx.all() |> Nx.to_number()
    end

    test "directed graph with weights" do
      vertices = ["a", "b", "c", "d", "e", "f", "g", "h"]

      edges = [
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
        ["g", "h"]
      ]

      weights = Enum.to_list(1..12)

      g = LAG.Graph.new(vertices, edges, type: :directed, weights: weights)

      adjacency_matrix =
        Nx.tensor([
          [0, 1, 0, 0, 0, 0, 0, 0],
          [0, 0, 2, 0, 3, 4, 0, 0],
          [0, 0, 0, 5, 0, 0, 6, 0],
          [0, 0, 7, 0, 0, 0, 0, 8],
          [0, 0, 0, 0, 0, 9, 0, 0],
          [0, 0, 0, 0, 0, 0, 10, 0],
          [0, 0, 0, 0, 0, 11, 0, 12],
          [0, 0, 0, 0, 0, 0, 0, 0]
        ])

      assert Nx.equal(g.adjacency_matrix, adjacency_matrix) |> Nx.all() |> Nx.to_number()
    end
  end
end
