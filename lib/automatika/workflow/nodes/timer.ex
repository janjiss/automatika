defmodule Automatika.Workflow.Nodes.Timer do
  use GenServer

  # 5 minutes in milliseconds
  @off_delay 5 * 60 * 1000

  # Starting the server
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    outputs = opts[:outputs]
    delay = opts[:delay] || @off_delay
    {:ok, {outputs, delay, nil}}
  end

  def handle_cast({:publish, payload}, {outputs, delay, timer_ref}) do
    if timer_ref, do: Process.cancel_timer(timer_ref)

    new_timer_ref = Process.send_after(self(), {:tick, payload}, delay)
    {:noreply, {outputs, delay, new_timer_ref}}
  end

  def handle_info({:tick, payload}, {outputs, delay, timer_ref}) do
    Enum.each(outputs, fn output ->
      GenServer.cast(output, {:publish, payload})
    end)

    {:noreply, {outputs, delay, timer_ref}}
  end
end
