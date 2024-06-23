defmodule Automatika.Workflow.Nodes.MQTTOutTest do
  use ExUnit.Case

  test "sends message to output_1 when sun is up" do
    topics = ["lamp"]
    payload = %{"payload_key" => "payload_value"}
    self_pid = self()

    mqtt_module =
      spawn(fn ->
        receive do
          {:"$gen_cast", {:publish, ["lamp"], %{"payload_key" => "payload_value"}}} ->
            send(self_pid, :received)
        end
      end)

    {:ok, pid} =
      Automatika.Workflow.Nodes.MQTTOut.start_link(
        outputs: [self()],
        mqtt_module: mqtt_module,
        topics: topics
      )

    GenServer.cast(pid, {:publish, payload})

    assert_receive(:received)
  end
end
