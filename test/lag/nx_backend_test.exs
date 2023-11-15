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
end
