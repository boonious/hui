defmodule Hui.Utils.ParserType do
  @moduledoc false

  alias Hui.Query.Common

  @json_parser Application.compile_env(:hui, :json_parser)

  @type query :: Hui.query()

  @spec not_configured() :: :not_configured
  def not_configured(), do: :not_configured

  @spec infer(query) :: {:ok, module}
  def infer(%Common{wt: response_writer}), do: parser_for(response_writer)
  def infer(query) when is_map(query), do: Map.get(query, :wt) |> parser_for()

  def infer(queries) when is_list(queries) do
    response_writer =
      Enum.reduce_while(queries, nil, fn query, acc ->
        case query do
          %Common{} = query -> {:halt, query.wt}
          {:wt, value} -> {:halt, value}
          _ -> {:cont, acc}
        end
      end)

    parser_for(response_writer)
  end

  defp parser_for("json"), do: @json_parser
  defp parser_for(nil), do: @json_parser
  defp parser_for(_other_response_writer), do: nil
end
