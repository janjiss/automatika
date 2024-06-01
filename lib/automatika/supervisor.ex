defmodule Automatika.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      Supervisor.child_spec(
        {Automatika.Workflow.Components.MQTT,
         %{
           emqtt_host: Application.get_env(:automatika, :mqtt_host),
           emqtt_port: Application.get_env(:automatika, :mqtt_port),
           client_id: "automatika"
         }},
        id: :mqtt
      ),
      Supervisor.child_spec(
        {Automatika.Workflow.Nodes.TimedLight,
         %{
           sensor_topics: ["zigbee2mqtt/patio-sensor"],
           light_topics: ["zigbee2mqtt/patio-outlet/set"]
         }},
        id: :patio_light
      ),
      Supervisor.child_spec(
        {Automatika.Workflow.Nodes.TimedLight,
         %{
           sensor_topics: ["zigbee2mqtt/front-door-sensor-1", "zigbee2mqtt/front-door-sensor-2"],
           light_topics: [
             "zigbee2mqtt/front-door-lamp-1/set",
             "zigbee2mqtt/front-door-lamp-2/set"
           ]
         }},
        id: :front_door_light
      ),
      Supervisor.child_spec(
        {Automatika.Workflow.Nodes.OnOff,
         %{
           switch_topics: ["zigbee2mqtt/dirty-room-switch"],
           device_topics: ["zigbee2mqtt/dirty-room-outlet/set"]
         }},
        id: :dirty_room_outlet
      ),
      Supervisor.child_spec(
        {Automatika.Workflow.Nodes.OnOff,
         %{
           switch_topics: ["zigbee2mqtt/living-room-switch"],
           device_topics: ["zigbee2mqtt/living-room-outlet/set"]
         }},
        id: :living_room_outlet
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
