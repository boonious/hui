defmodule HuiEncoderTest do
  use ExUnit.Case, async: true

  alias Hui.Encoder

  test "encode/2 map" do
    assert Encoder.encode(%{q: "loch", rows: 10}) == "q=loch&rows=10"
  end

end