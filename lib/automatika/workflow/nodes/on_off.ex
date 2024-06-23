defmodule Automatika.Workflow.Nodes.OnOff do
  use GenServer
  alias Automatika.Workflow.Components.MQTTManager

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    switch_topics = opts[:switch_topics]
    device_topics = opts[:device_topics]

    {:ok,
     %{
       switch_topics: switch_topics,
       device_topics: device_topics,
       timer_ref: nil
     }, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, st = %{switch_topics: switch_topics}) do
    MQTTManager.subscribe(switch_topics, self())

    {:noreply, st}
  end

  def handle_cast({:publish, %{payload: payload}}, state) do
    state = handle_on_off(payload, state)
    {:noreply, state}
  end

  def handle_cast(_, state) do
    {:noreply, state}
  end

  defp handle_on_off(
         %{"action" => "on"},
         state = %{device_topics: device_topics}
       ) do
    MQTTManager.publish(device_topics, %{"state" => "ON"})

    state
  end

  defp handle_on_off(
         %{"action" => "off"},
         state = %{device_topics: device_topics}
       ) do
    MQTTManager.publish(device_topics, %{"state" => "OFF"})

    state
  end
end
