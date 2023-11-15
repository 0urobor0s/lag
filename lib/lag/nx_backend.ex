defmodule LAG.NxBackend do
  import Nx.Defn

  alias LAG.Graph

  @behaviour LAG.Backend

  defn adjacency_matrix(vertices, edges, opts) do
    {edge_n, _} = Nx.shape(edges)
    adjacency_matrix(vertices, edges, Nx.broadcast(1, {edge_n}), opts)
  end

  defn adjacency_matrix(vertices, edges, weights, opts) do
    {vertex_n} = Nx.shape(vertices)
    # {edge_n, _} = Nx.shape(edges)
    # {weights_n} = Nx.shape(weights)
    # assert edge_n == weights_n

    adjm =
      Nx.broadcast(0, {vertex_n, vertex_n})
      |> Nx.indexed_put(edges, weights)

    case opts[:type] do
      :undirected ->
        edges_inv = Nx.reverse(edges)
        weights_inv = Nx.reverse(weights)

        Nx.indexed_put(adjm, edges_inv, weights_inv)

      :directed ->
        adjm
    end
  end

  defnp modified_adjacency_matrix_n(adjacency_matrix) do
    # Should check if the value is `Nx.Constants.max_finite(Nx.type(adjacency_matrix))`
    # and warn accordingly
    max = Nx.sum(adjacency_matrix) + 1
    {n, _} = Nx.shape(adjacency_matrix)

    Nx.select(adjacency_matrix, adjacency_matrix, max)
    # Does not support self loops
    |> Nx.put_diagonal(Nx.broadcast(0, {n}))
  end

  # Min-plus matrix multiplication, also known as min-plus products or distance product.
  deftransform min_plus_dot(%Graph{} = graph) do
    graph.adjacency_matrix
    |> modified_adjacency_matrix_n()
    |> min_plus_dot_n()
  end

  defn min_plus_dot_n(a, b) do
    {n, _} = Nx.shape(a)

    while {a, b, hop = Nx.broadcast(0, {n, n}), d = Nx.broadcast(0, {n, n})}, i <- 0..(n - 1) do
      ri = Nx.slice(a, [i, 0], [1, n]) |> Nx.transpose()
      add_ci = Nx.add(ri, b)
      min_ci = add_ci |> Nx.reduce_min(axes: [0], keep_axes: true)
      min_ki = add_ci |> Nx.argmin(axis: 0, keep_axis: true)

      {a, b, Nx.put_slice(hop, [i, 0], min_ci), Nx.put_slice(d, [i, 0], min_ki)}
    end
    |> then(&{elem(&1, 2), elem(&1, 3)})
  end

  defn min_plus_dot_n(a) do
    min_plus_dot_n(a, a)
  end

  deftransform diamond_pow(%Graph{} = graph, k) do
    k_tensor = Nx.broadcast(0, {k})
    a = modified_adjacency_matrix_n(graph.adjacency_matrix)
    diamond_pow_n(a, k_tensor)
  end

  deftransform diamond_pow(a, k) do
    k_tensor = Nx.broadcast(0, {k})
    diamond_pow_n(a, k_tensor)
  end

  defnp diamond_pow_n(a, k_tensor) do
    {n, _} = Nx.shape(a)
    {k} = Nx.shape(k_tensor)

    while {a, bn = a, dr = Nx.broadcast(0, {k, n, n})}, i <- 0..(k - 1) do
      {bn, dn} = min_plus_dot_n(a, bn)
      dn = Nx.reshape(dn, {1, n, n})

      {a, bn, Nx.put_slice(dr, [i, n, n], dn)}
    end
    |> then(&{elem(&1, 1), elem(&1, 2)})
  end

  deftransform diamond_pow_2r(%Graph{} = graph) do
    {n, _} = Nx.shape(graph.adjacency_matrix)
    # r = Nx.log(n - 1, 2) |> Nx.ceil() |> Nx.as_type(:s64)
    r = :math.log2(n - 1) |> :erlang.ceil()
    r_tensor = Nx.broadcast(0, {r})
    diamond_pow_2r_n(graph.adjacency_matrix, r_tensor)
  end

  # needs r > 1
  defnp diamond_pow_2r_n(adjacency_matrix, r_tensor) do
    {n, _} = Nx.shape(adjacency_matrix)
    {r} = Nx.shape(r_tensor)
    inc = modified_adjacency_matrix_n(adjacency_matrix)

    while {bn = inc, dr = Nx.broadcast(0, {r, n, n})}, i <- 0..(r - 1) do
      {bn, dn} = min_plus_dot_n(bn)

      {bn, Nx.put_slice(dr, [i, n, n], Nx.reshape(dn, {1, n, n}))}
    end
  end

  def shortest_path(%Graph{} = graph, a, b, _opts \\ []) do
    a = Map.fetch!(graph.vertices.map, a)
    b = Map.fetch!(graph.vertices.map, b)

    graph
    |> shortest_path_r(a, b)
    |> Graph.index_to_map(graph)
  end

  defp shortest_path_r(graph, a, b) do
    edge =
      graph.adjacency_matrix
      |> Nx.slice([a, b], [1, 1])
      |> Nx.squeeze()
      |> Nx.to_number()

    if edge != 0 do
      if a == b do
        [a]
      else
        [a, b]
      end
    else
      {_, dr} = diamond_pow_2r(graph)
      {r, _, _} = Nx.shape(dr)
      r = r - 1
      k = Nx.slice(dr, [r, a, b], [1, 1, 1]) |> Nx.squeeze() |> Nx.to_number()

      ([a] ++ shortest_path_a(dr, a, k, r - 1) ++ shortest_path_a(dr, k, b, r - 1) ++ [b])
      |> Enum.uniq()
      |> shortest_path_l()
    end
  end

  defp shortest_path_l(path) when length(path) > 2, do: path
  defp shortest_path_l(_path), do: []

  defp shortest_path_a(_, _, _, -1), do: []

  defp shortest_path_a(dr, a, b, r) do
    k = Nx.slice(dr, [r, a, b], [1, 1, 1]) |> Nx.squeeze() |> Nx.to_number()
    shortest_path_a(dr, a, k, r - 1) ++ [k] ++ shortest_path_a(dr, k, b, r - 1)
  end

  def all_pairs_shortest_path(%Graph{} = graph, opts \\ []) do
    graph
    |> permutations()
    |> Enum.into(%{}, fn [a, b] = l -> {l, shortest_path(graph, a, b, opts)} end)
  end

  def permutations(graph) do
    vertices = Map.keys(graph.vertices.map)
    for a <- vertices, b <- vertices, do: [a, b]
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
