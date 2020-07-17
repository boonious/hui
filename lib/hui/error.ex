defmodule Hui.Error do
  defexception [:reason]
  @type t :: %__MODULE__{reason: :inet.posix() | term}

  @impl true
  def message(%__MODULE__{reason: reason}), do: inspect(reason)
end
