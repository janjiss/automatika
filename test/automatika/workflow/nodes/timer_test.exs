defmodule Automatika.Workflow.Nodes.TimerTest do
  use ExUnit.Case

  test "receiving multiple messages and resetting the timer and then forwarding the message" do
    payload_1 = %{"movement" => false}
    payload_2 = %{"movement" => true}

    {:ok, timer_pid} =
      Automatika.Workflow.Nodes.Timer.start_link(
        outputs: [self()],
        delay: 3 * 100
      )

    GenServer.cast(timer_pid, {:publish, payload_1})
    GenServer.cast(timer_pid, {:publish, payload_2})

    assert_receive {:"$gen_cast", {:publish, ^payload_2}}, 4 * 100
    refute_receive {:"$gen_cast", {:publish, ^payload_1}}, 4 * 100
  end
end
