defmodule Automatika.Workflow.Nodes.Sunset do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    outputs = opts[:outputs]

    {:ok, {outputs}}
  end

  def handle_cast(
        {:publish, payload},
        state = {outputs}
      ) do
    case is_sun_up?() do
      true ->
        outputs
        |> Enum.at(0)
        |> GenServer.cast({:publish, payload})

      false ->
        outputs
        |> Enum.at(1)
        |> GenServer.cast({:publish, payload})
    end

    {:noreply, state}
  end

  defp is_sun_up? do
    now = DateTime.utc_now()
    {:ok, sunset} = Astro.sunset({21.95721, 56.97399}, now, time_zone: "UTC")
    {:ok, sunrise} = Astro.sunrise({21.95721, 56.97399}, now, time_zone: "UTC")

    DateTime.compare(now, sunrise) in [:gt, :eq] and DateTime.compare(now, sunset) in [:lt, :eq]
  end
end
