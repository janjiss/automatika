defmodule Automatika.Workflow.Nodes.LuaBooleanTest do
  use ExUnit.Case

  test "receive message & returns boolean result from lua script" do
    payload = %{"movement" => true}

    self_pid = self()

    output_1 =
      spawn(fn ->
        receive do
          message ->
            send(self_pid, :output_1)
        end
      end)

    output_2 =
      spawn(fn ->
        receive do
          message ->
            send(self_pid, :output_2)
        end
      end)

    lua_script = """
      return payload.movement
    """

    {:ok, lua_boolean_pid} =
      Automatika.Workflow.Nodes.LuaBoolean.start_link(
        outputs: [output_1, output_2],
        lua_script: lua_script
      )

    GenServer.cast(lua_boolean_pid, {:publish, %{"movement" => true}})
    assert_receive :output_1

    GenServer.cast(lua_boolean_pid, {:publish, %{"movement" => false}})
    assert_receive :output_2
  end
end
