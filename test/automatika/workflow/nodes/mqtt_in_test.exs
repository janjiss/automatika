defmodule Automatika.Workflow.Nodes.MQTTInTest do
  use ExUnit.Case

  test "send message to outputs on mqtt_in message" do
    topics = ["lamp"]
    payload = %{"payload_key" => "payload_value"}

    mqtt_module =
      spawn(fn ->
        receive do
          {:"$gen_cast", {:subscribe, ["lamp"], pid}} ->
            GenServer.cast(pid, {:publish, payload})
        end
      end)

    Automatika.Workflow.Nodes.MQTTIn.start_link(
      outputs: [self()],
      mqtt_module: mqtt_module,
      topics: topics
    )

    assert_receive({:"$gen_cast", {:publish, ^payload}})
  end
end
