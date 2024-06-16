defmodule Automatika.Workflow.Nodes.Sunset do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    output_1 = opts[:output_1]
    output_2 = opts[:output_2]

    {:ok, %{output_1: output_1, output_2: output_2}}
  end

  def handle_cast(
        {:publish, payload},
        state = %{output_1: output_1, output_2: output_2}
      ) do
    case is_sun_up?() do
      true -> GenServer.cast(output_1, {:publish, payload})
      false -> GenServer.cast(output_2, {:publish, payload})
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
