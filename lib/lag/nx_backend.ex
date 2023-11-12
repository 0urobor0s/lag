defmodule LAG.NxBackend do
  import Nx.Defn

  alias LAG.Graph

  @behaviour LAG.Backend

  defn adjacency_matrix(vertices, edges, _opts) do
    {vertex_n} = Nx.shape(vertices)
    {edge_n, _} = Nx.shape(edges)
    # edges_inv = Nx.tile(edges, [2])[[0..-1//1, 1..2]]
    edges_inv = Nx.reverse(edges)

    _adjm =
      Nx.broadcast(0, {vertex_n, vertex_n})
      |> Nx.indexed_put(edges, Nx.broadcast(1, {edge_n}))
      |> Nx.indexed_put(edges_inv, Nx.broadcast(1, {edge_n}))
      # Remove when support for weighted edges is added
      |> Nx.as_type(vertices.type)
  end

  # Currently no self node edge is support as it should count twice
  @impl true
  deftransform degree_matrix(%Graph{} = graph) do
    degree_matrix_n(graph.adjacency_matrix)
  end

  defnp degree_matrix_n(adjacency_matrix) do
    adjacency_matrix
    |> Nx.sum(axes: [1])
    |> Nx.make_diagonal()
  end
end
