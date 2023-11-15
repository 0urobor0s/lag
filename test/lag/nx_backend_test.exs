defmodule LAG.NxBackendTest do
  use ExUnit.Case
  import LAG.GraphFixtures
  doctest LAG.Graph

  describe "shortest_path/4" do
    test "when exists, returns path" do
      graph = graph_fixture(%{opts: [type: :directed]})
      assert LAG.NxBackend.shortest_path(graph, "a", "g") == ["a", "b", "c", "g"]
    end

    test "when does not exist, returns empty list" do
      graph = graph_fixture(%{opts: [type: :directed]})
      assert LAG.NxBackend.shortest_path(graph, "g", "a") == []
    end
  end

  describe "all_pairs_shortest_path/2" do
    test "return a possible shortest path for all pairs" do
      graph = graph_fixture(%{opts: [type: :directed]})

      result = %{
        ["a", "a"] => [],
        ["a", "b"] => ["a", "b"],
        ["a", "c"] => ["a", "b", "c"],
        ["a", "d"] => ["a", "b", "c", "d"],
        ["a", "e"] => ["a", "b", "e"],
        ["a", "f"] => ["a", "b", "f"],
        ["a", "g"] => ["a", "b", "c", "g"],
        ["a", "h"] => ["a", "b", "c", "d", "h"],
        ["b", "a"] => [],
        ["b", "b"] => [],
        ["b", "c"] => ["b", "c"],
        ["b", "d"] => ["b", "c", "d"],
        ["b", "e"] => ["b", "e"],
        ["b", "f"] => ["b", "f"],
        ["b", "g"] => ["b", "c", "g"],
        ["b", "h"] => ["b", "c", "d", "h"],
        ["c", "a"] => [],
        ["c", "b"] => [],
        ["c", "c"] => [],
        ["c", "d"] => ["c", "d"],
        ["c", "e"] => [],
        ["c", "f"] => ["c", "g", "f"],
        ["c", "g"] => ["c", "g"],
        ["c", "h"] => ["c", "d", "h"],
        ["d", "a"] => [],
        ["d", "b"] => [],
        ["d", "c"] => ["d", "c"],
        ["d", "d"] => [],
        ["d", "e"] => [],
        ["d", "f"] => ["d", "c", "g", "f"],
        ["d", "g"] => ["d", "c", "g"],
        ["d", "h"] => ["d", "h"],
        ["e", "a"] => [],
        ["e", "b"] => [],
        ["e", "c"] => [],
        ["e", "d"] => [],
        ["e", "e"] => [],
        ["e", "f"] => ["e", "f"],
        ["e", "g"] => ["e", "f", "g"],
        ["e", "h"] => ["e", "f", "g", "h"],
        ["f", "a"] => [],
        ["f", "b"] => [],
        ["f", "c"] => [],
        ["f", "d"] => [],
        ["f", "e"] => [],
        ["f", "f"] => [],
        ["f", "g"] => ["f", "g"],
        ["f", "h"] => ["f", "g", "h"],
        ["g", "a"] => [],
        ["g", "b"] => [],
        ["g", "c"] => [],
        ["g", "d"] => [],
        ["g", "e"] => [],
        ["g", "f"] => ["g", "f"],
        ["g", "g"] => [],
        ["g", "h"] => ["g", "h"],
        ["h", "a"] => [],
        ["h", "b"] => [],
        ["h", "c"] => [],
        ["h", "d"] => [],
        ["h", "e"] => [],
        ["h", "f"] => [],
        ["h", "g"] => [],
        ["h", "h"] => ["h"]
      }

      assert LAG.NxBackend.all_pairs_shortest_path(graph) == result
    end
  end
end
