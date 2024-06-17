defmodule Automatika.Workflow.Nodes.LuaTest do
  use ExUnit.Case

  test "receive message & modifies the payload with lua" do
    payload = %{"movement" => true}

    lua_script = """
      payload.on = true
      return payload
    """

    {:ok, lua_pid} =
      Automatika.Workflow.Nodes.Lua.start_link(%{output_1: self(), lua_script: lua_script})

    GenServer.cast(lua_pid, {:publish, payload})
    assert_receive {:"$gen_cast", {:publish, %{"on" => true, "movement" => true}}}
  end
end
