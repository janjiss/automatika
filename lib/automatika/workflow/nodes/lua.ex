defmodule Automatika.Workflow.Nodes.Lua do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    lua_script = opts[:lua_script]
    output_1 = opts[:output_1]

    {:ok, %{output_1: output_1, lua_script: lua_script}}
  end

  def handle_cast({:publish, payload}, state = %{output_1: output_1, lua_script: lua_script}) do
    modified_payload = execute_lua_script(lua_script, payload)
    GenServer.cast(output_1, {:publish, modified_payload})
    {:noreply, state}
  end

  defp execute_lua_script(lua_script, payload) do
    lua = Lua.set!(Lua.new(), [:payload], payload)
    {[result], _} = Lua.eval!(lua, lua_script)
    Lua.Table.deep_cast(result)
  end
end
