defmodule Automatika.Workflow.Components.MQTTManager do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    emqtt_host = opts[:emqtt_host]
    emqtt_port = opts[:emqtt_port]
    client_id = opts[:client_id]

    {:ok, emqtt_pid} =
      :emqtt.start_link(
        host: emqtt_host,
        port: emqtt_port,
        clientid: client_id,
        clean_start: true,
        force_ping: true,
        keepalive: 600
      )

    {:ok,
     %{
       emqtt_pid: emqtt_pid,
       subscribers: %{}
     }, {:continue, :start_emqtt}}
  end

  def handle_continue(:start_emqtt, st = %{emqtt_pid: emqtt_pid}) do
    {:ok, _} = :emqtt.connect(emqtt_pid)

    {:noreply, st}
  end

  def handle_info(
        {:publish, %{payload: payload, topic: topic}},
        state = %{subscribers: subscribers}
      ) do
    subscriber_pids = Map.get(subscribers, topic, [])

    Enum.each(subscriber_pids, fn subscriber_pid ->
      GenServer.cast(subscriber_pid, {:publish, %{payload: Jason.decode!(payload)}})
    end)

    {:noreply, state}
  end

  def handle_cast(
        {:subscribe, topics, pid},
        state = %{subscribers: subscribers, emqtt_pid: emqtt_pid}
      ) do
    Enum.each(topics, fn topic ->
      :emqtt.subscribe(emqtt_pid, {topic, 0})
    end)

    new_subscribers =
      Enum.reduce(topics, subscribers, fn topic, acc ->
        Map.update(acc, topic, [pid], fn existing_pids -> [pid | existing_pids] end)
      end)

    {:noreply, Map.put(state, :subscribers, new_subscribers)}
  end

  def handle_cast({:publish, topics, payload}, state = %{emqtt_pid: emqtt_pid}) do
    Enum.each(topics, fn topic ->
      :emqtt.publish(emqtt_pid, topic, Jason.encode!(payload))
    end)

    {:noreply, state}
  end

  def subscribe(topics, pid) do
    GenServer.cast(__MODULE__, {:subscribe, topics, pid})
  end

  def publish(topics, payload) do
    GenServer.cast(__MODULE__, {:publish, topics, payload})
  end
end
