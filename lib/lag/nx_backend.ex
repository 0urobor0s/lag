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

  deftransform laplacian_matrix(%Graph{} = graph) do
    laplacian_matrix_n(graph.adjacency_matrix)
  end

  defnp laplacian_matrix_n(adjacency_matrix) do
    degree_matrix_n(adjacency_matrix) - adjacency_matrix
  end

  defn algebraic_connectivity(adjacency_matrix) do
    laplacian_matrix = laplacian_matrix_n(adjacency_matrix)
    {eigenvals, _eigenvecs} = Nx.LinAlg.eigh(laplacian_matrix)
    zero_i = Nx.argmin(eigenvals) |> Nx.new_axis(0)

    eigenvals
    |> eigenvals_fiedler_update(zero_i)
    |> Nx.reduce_min()
  end

  defn fiedler_vector(adjacency_matrix) do
    laplacian_matrix = laplacian_matrix_n(adjacency_matrix)
    {eigenvals, eigenvecs} = Nx.LinAlg.eigh(laplacian_matrix)
    zero_i = Nx.argmin(eigenvals) |> Nx.new_axis(0)
    index = Nx.argmin(eigenvals_fiedler_update(eigenvals, zero_i))

    eigenvecs[[0..-1//1, index]]
  end

  defn connected(adjacency_matrix) do
    adjacency_matrix
    |> laplacian_matrix_n()
    |> algebraic_connectivity()
    |> Nx.greater(0)
  end

  defnp eigenvals_fiedler_update(eigenvals, index) do
    # Can be any value greater than 1
    Nx.indexed_put(eigenvals, index, Nx.tensor(2))
  end
end
