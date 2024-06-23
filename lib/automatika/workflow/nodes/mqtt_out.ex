defmodule Automatika.Workflow.Nodes.MQTTOut do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    mqtt_module = opts[:mqtt_module] || Automatika.Workflow.Components.MQTTManager
    topics = opts[:topics]

    {:ok, {mqtt_module, topics}}
  end

  def handle_cast(
        {:publish, payload},
        state = {mqtt_module, topics}
      ) do
    GenServer.cast(mqtt_module, {:publish, topics, payload})

    {:noreply, state}
  end
end
