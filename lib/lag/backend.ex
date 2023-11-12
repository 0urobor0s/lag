defmodule LAG.Backend do
  @moduledoc """
  The behaviour for graph operations backends.
  """

  @type matrix :: Nx.Tensor.t()
  @type graph :: LAG.Graph.t()

  @callback degree_matrix(graph) :: matrix
end
