defmodule LAG do
  @moduledoc """
  Documentation for `LAG`.
  """

  import LAG.Shared

  alias LAG.Graph

  def degree_matrix(%Graph{} = graph) do
    impl!(graph).degree_matrix(graph)
  end

  def default_backend() do
    Process.get(backend_pdict_key()) || backend!(Application.fetch_env!(:lag, :default_backend))
  end

  def default_backend(backend) do
    Process.put(backend_pdict_key(), backend!(backend)) ||
      backend!(Application.fetch_env!(:lag, :default_backend))
  end

  ## Helpers

  defp backend!(backend) when is_atom(backend) do
    backend!({backend, []})
  end

  defp backend!({backend, options}) when is_atom(backend) and is_list(options) do
    # {backend, backend.init(options)}
    {backend, []}
  end

  defp backend!(other) do
    raise ArgumentError,
          "backend must be an atom or a tuple {backend, options}, got: #{inspect(other)}"
  end
end
