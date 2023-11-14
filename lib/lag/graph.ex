defmodule LAG.Graph do
  graph_schema = [
    backend: [
      type: :mod_arg
    ],
    type: [
      type: {:in, [:undirected, :directed]},
      default: :undirected,
      doc: """
      The type of graph, which can be undirected (default) or directed.
      """
    ],
    weights: [
      type: {:list, :integer},
      doc: """
      The weights of each edge in order of the edges given.
      """
    ]
  ]

  @graph_schema NimbleOptions.new!(graph_schema)

  @derive {Nx.Container, containers: [:adjacency_matrix]}
  @enforce_keys [:type, :adjacency_matrix, :vertices]
  defstruct [:type, :adjacency_matrix, :backend, vertices: %{}]

  @type vertex_id :: non_neg_integer()
  @type vertex :: term()
  @type vertices_index :: %{vertex_id => vertex}
  @type vertices_map :: %{vertex => vertex_id}
  @type vertices :: %{:index => vertices_index, :map => vertices_map}
  @type graph_type :: :directed | :undirected
  @type adjacency_matrix :: Nx.Tensor.t()
  @type t :: %__MODULE__{
          vertices: vertices,
          type: graph_type,
          adjacency_matrix: adjacency_matrix,
          backend: {atom(), list()}
        }

  @doc """
  Creates a new Graph struct.

  ## Options

  #{NimbleOptions.docs(@graph_schema)}

  ## Examples

      iex> vertices = Nx.tensor([0, 1, 2, 3, 4, 5])
      iex> edges = Nx.tensor([[0, 1], [0, 4], [1, 4], [1, 2], [2, 3], [3, 4], [3, 5]])
      iex> graph = LAG.Graph.new(vertices, edges)
      iex> graph.adjacency_matrix
      #Nx.Tensor<
        s64[6][6]
        [
          [0, 1, 0, 0, 1, 0],
          [1, 0, 1, 0, 1, 0],
          [0, 1, 0, 1, 0, 0],
          [0, 0, 1, 0, 1, 1],
          [1, 1, 0, 1, 0, 0],
          [0, 0, 0, 1, 0, 0]
        ]
      >

      iex> vertices = ["a", "b", "c"]
      iex> edges = [["a", "b"], ["b", "c"], ["c", "a"]]
      iex> LAG.Graph.new(vertices, edges, type: :directed)
      #LAG.Graph<type: directed, vertices: ["a", "b", "c"], edges: [["a", "b"], ["b", "c"], ["c", "a"]], adjacency_matrix: #Nx.Tensor<
        s64[3][3]
        [
          [0, 1, 0],
          [0, 0, 1],
          [1, 0, 0]
        ]
      >>

      iex> vertices = ["a", "b", "c"]
      iex> edges = [["a", "b"], ["b", "c"], ["c", "a"]]
      iex> weights = [1, 2, 1]
      iex> LAG.Graph.new(vertices, edges, type: :directed, weights: weights)
      #LAG.Graph<type: directed, vertices: ["a", "b", "c"], edges: [["a", "b"], ["b", "c"], ["c", "a"]], adjacency_matrix: #Nx.Tensor<
        s64[3][3]
        [
          [0, 1, 0],
          [0, 0, 2],
          [1, 0, 0]
        ]
      >>
  """

  def new(vertices, edges, opts \\ [])

  def new(%Nx.Tensor{} = vertices, %Nx.Tensor{} = edges, opts) do
    vertices_map =
      vertices
      |> Nx.to_list()
      |> Enum.with_index(fn element, index -> {element, index} end)
      |> Enum.into(%{})

    new_a(vertices, edges, vertices_map, opts)
  end

  def new(vertices, edges, opts) when is_list(vertices) and is_list(edges) do
    vertices_map =
      vertices
      |> Enum.with_index(fn element, index -> {element, index} end)
      |> Enum.into(%{})

    edges_tensor =
      edges
      |> Enum.map(fn [a, b] ->
        [Map.fetch!(vertices_map, a), Map.fetch!(vertices_map, b)]
      end)
      |> Nx.tensor()

    vertices_tensor =
      vertices_map
      |> Map.values()
      |> Nx.tensor()

    new_a(vertices_tensor, edges_tensor, vertices_map, opts)
  end

  defp new_a(vertices, edges, vertices_map, opts) do
    # backend = {impl, _} = LAG.Shared.backend_from_options!(opts)
    backend = {impl, _} = {LAG.NxBackend, []}
    opts = NimbleOptions.validate!(opts, @graph_schema)

    vertices_index = Enum.into(vertices_map, %{}, fn {k, v} -> {v, k} end)

    adjacency_matrix =
      case opts[:weights] do
        nil -> impl.adjacency_matrix(vertices, edges, opts)
        [] -> impl.adjacency_matrix(vertices, edges, opts)
        weights -> impl.adjacency_matrix(vertices, edges, Nx.tensor(weights), opts)
      end

    %__MODULE__{
      type: opts[:type],
      vertices: %{:index => vertices_index, :map => vertices_map},
      # type is currently ingnored and is always undirected
      adjacency_matrix: adjacency_matrix,
      backend: backend
    }
  end

  def index_to_map(list, %__MODULE__{} = graph) when is_list(list) do
    Enum.map(list, fn elem -> Map.fetch!(graph.vertices.index, elem) end)
  end

  def index_to_map(e, %__MODULE__{} = graph) when is_integer(e) do
    Map.fetch!(graph.vertices.index, e)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(
          %LAG.Graph{type: type, vertices: vertices, adjacency_matrix: adjacency_matrix},
          opts
        ) do
      vertices_o = Map.keys(vertices.map)
      edges = edges_a(adjacency_matrix, vertices.index)

      concat([
        "#LAG.Graph<",
        "type: #{type}, ",
        "vertices: ",
        Inspect.List.inspect(vertices_o, opts),
        ", edges: ",
        Inspect.List.inspect(edges, opts),
        ", adjacency_matrix: ",
        Inspect.Nx.Tensor.inspect(adjacency_matrix, opts),
        ">"
      ])
    end

    defp edges_a(adjacency_matrix, vertices_index) do
      adjacency_matrix
      |> Nx.to_list()
      |> Enum.with_index()
      |> Enum.flat_map(fn {l, i} ->
        Enum.with_index(l, fn e, j ->
          if e != 0 do
            [i, j]
          else
            []
          end
        end)
      end)
      |> Enum.reject(fn l -> l == [] end)
      # Maybe remove unnecessary when type is undirected
      |> Enum.map(fn l -> index_to_edge(l, vertices_index) end)
    end

    defp index_to_edge(list, vertices_index) do
      Enum.map(list, fn elem -> Map.fetch!(vertices_index, elem) end)
    end
  end
end
