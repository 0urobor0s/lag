defmodule LAG.Graph do
  # @graph_types [:directed, :undirected]

  @derive {Nx.Container, containers: [:adjacency_matrix]}
  @enforce_keys [:type, :adjacency_matrix, :vertices]
  defstruct [:type, :adjacency_matrix, :backend, vertices: %{}]

  @type vertex_id :: non_neg_integer()
  @type vertex :: term()
  @type vertices :: %{vertex_id => vertex}
  @type graph_type :: :directed | :undirected
  @type adjacency_matrix :: Nx.Tensor.t()
  @type t :: %__MODULE__{
          vertices: vertices,
          type: graph_type,
          adjacency_matrix: adjacency_matrix,
          backend: {atom(), list()}
        }

  def new(%Nx.Tensor{} = vertices, %Nx.Tensor{} = edges, opts \\ []) do
    # backend = {impl, _} = LAG.Shared.backend_from_options!(opts)
    backend = {impl, _} = {LAG.NxBackend, []}
    {_type, _opts} = Keyword.pop(opts, :type, :directed)

    vertices_map =
      vertices
      |> Nx.to_list()
      |> Enum.with_index(fn element, index -> {index, element} end)
      |> Enum.into(%{})

    %__MODULE__{
      type: :undirected,
      vertices: vertices_map,
      # type is currently ingnored and is always undirected
      adjacency_matrix: impl.adjacency_matrix(vertices, edges, opts),
      backend: backend
    }
  end
end
