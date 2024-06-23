defmodule Automatika.Workflow.Nodes.TimedLight do
  use GenServer
  alias Automatika.Workflow.Components.MQTTManager

  # 5 minutes in milliseconds
  @off_delay 5 * 60 * 1000

  # Starting the server
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    sensor_topics = opts[:sensor_topics]
    light_topics = opts[:light_topics]

    {:ok,
     %{
       sensor_topics: sensor_topics,
       light_topics: light_topics,
       timer_ref: nil
     }, {:continue, :subscribe}}
  end

  def handle_continue(:subscribe, st = %{sensor_topics: sensor_topics}) do
    MQTTManager.subscribe(sensor_topics, self())

    {:noreply, st}
  end

  def handle_cast(
        {:publish, %{payload: payload}},
        state
      ) do
    {:noreply, handle_occupancy(payload, state)}
  end

  def handle_info(:turn_off_light, st = %{light_topics: light_topics}) do
    MQTTManager.publish(light_topics, turn_off_signal())

    {:noreply, %{st | timer_ref: nil}}
  end

  defp handle_occupancy(
         %{"occupancy" => true},
         st = %{light_topics: light_topics, timer_ref: timer_ref}
       ) do
    case is_sun_up?() do
      true ->
        MQTTManager.publish(light_topics, turn_off_signal())

      false ->
        MQTTManager.publish(light_topics, turn_on_signal())
    end

    if timer_ref, do: Process.cancel_timer(timer_ref)
    new_timer_ref = Process.send_after(self(), :turn_off_light, @off_delay)
    %{st | timer_ref: new_timer_ref}
  end

  defp handle_occupancy(
         %{"occupancy" => false},
         state
       ) do
    state
  end

  defp turn_off_signal do
    %{"state" => "OFF"}
  end

  defp turn_on_signal do
    %{"state" => "ON"}
  end

  defp is_sun_up? do
    now = DateTime.utc_now()
    {:ok, sunset} = Astro.sunset({21.95721, 56.97399}, now, time_zone: "UTC")
    {:ok, sunrise} = Astro.sunrise({21.95721, 56.97399}, now, time_zone: "UTC")

    DateTime.compare(now, sunrise) in [:gt, :eq] and DateTime.compare(now, sunset) in [:lt, :eq]
  end
end
