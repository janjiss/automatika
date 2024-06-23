defmodule Automatika.Workflow.Nodes.Lua do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    lua_script = opts[:lua_script]
    outputs = opts[:outputs]

    {:ok, {outputs, lua_script}}
  end

  def handle_cast({:publish, payload}, state = {outputs, lua_script}) do
    modified_payload = execute_lua_script(lua_script, payload)

    outputs
    |> Enum.at(0)
    |> GenServer.cast({:publish, modified_payload})

    {:noreply, state}
  end

  defp execute_lua_script(lua_script, payload) do
    lua = Lua.set!(Lua.new(), [:payload], payload)
    {[result], _} = Lua.eval!(lua, lua_script)
    Lua.Table.deep_cast(result)
  end
end
