defmodule Automatika.Workflow.Nodes.MQTTIn do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    mqtt_module = opts[:mqtt_module] || Automatika.Workflow.Components.MQTTManager
    topics = opts[:topics]
    outputs = opts[:outputs]

    {:ok, {mqtt_module, topics, outputs}, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, state = {mqtt_module, topics, _}) do
    GenServer.cast(mqtt_module, {:subscribe, topics, self()})

    {:noreply, state}
  end

  def handle_cast({:publish, payload}, state = {_, _, outputs}) do
    Enum.each(outputs, fn output ->
      GenServer.cast(output, {:publish, payload})
    end)

    {:noreply, state}
  end
end
