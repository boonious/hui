defmodule Hui.Http.Clients do
  @moduledoc """
  A before compile hook that returns all existing HTTP clients.
  """

  defmacro __before_compile__(env) do
    Module.register_attribute(env.module, :clients, accumulate: true)

    File.ls!("lib/hui/http/clients")
    |> Enum.each(fn file ->
      name = String.split(file, ".ex") |> hd |> Macro.camelize()
      Module.put_attribute(env.module, :clients, Module.concat(Hui.Http.Clients, name))
    end)

    quote do
      def all_clients, do: @clients
    end
  end
end
