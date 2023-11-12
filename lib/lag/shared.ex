defmodule LAG.Shared do
  alias LAG.Graph

  @doc """
  Gets the implementation of a graph.
  """
  def impl!(%Graph{backend: {backend, _opts}}), do: backend
  # For Nx JIT
  def impl!(%Graph{}), do: LAG.NxBackend

  @doc """
  The process dictionary key to store default backend under.
  """
  def backend_pdict_key, do: {LAG, :default_backend}
end
