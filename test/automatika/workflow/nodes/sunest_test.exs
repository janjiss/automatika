defmodule Automatika.Workflow.Nodes.SunsetTest do
  use ExUnit.Case
  alias Automatika.Workflow.Nodes.Sunset

  import Mock

  setup do
    self_pid = self()
    payload = %{payload: %{}}

    output_1 =
      spawn(fn ->
        receive do
          message ->
            assert(message == {:"$gen_cast", {:publish, payload}})
            send(self_pid, :output_1)
        end
      end)

    output_2 =
      spawn(fn ->
        receive do
          message ->
            assert(message == {:"$gen_cast", {:publish, payload}})
            send(self_pid, :output_2)
        end
      end)

    {:ok, outputs: [output_1, output_2], payload: payload}
  end

  test "sends message to output_1 when sun is up",
       %{outputs: outputs, payload: payload} = _context do
    with_mocks [
      {Astro, [],
       [
         sunset: fn _, _, _ -> {:ok, DateTime.add(DateTime.utc_now(), 60)} end,
         sunrise: fn _, _, _ -> {:ok, DateTime.add(DateTime.utc_now(), -60)} end
       ]}
    ] do
      {:ok, sunset_pid} = Sunset.start_link(outputs: outputs)
      GenServer.cast(sunset_pid, {:publish, payload})

      assert_receive :output_1
    end
  end

  test "sends message to output_2 when sun is down",
       %{outputs: outputs, payload: payload} = _context do
    with_mocks [
      {Astro, [],
       [
         sunset: fn _, _, _ -> {:ok, DateTime.add(DateTime.utc_now(), -60)} end,
         sunrise: fn _, _, _ -> {:ok, DateTime.add(DateTime.utc_now(), 60)} end
       ]}
    ] do
      {:ok, sunset_pid} = Sunset.start_link(outputs: outputs)
      GenServer.cast(sunset_pid, {:publish, payload})

      assert_receive :output_2
    end
  end
end
