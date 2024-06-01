defmodule Automatika.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AutomatikaWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:automatika, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Automatika.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Automatika.Finch},
      # Start a worker by calling: Automatika.Worker.start_link(arg)
      # {Automatika.Worker, arg},
      # Start to serve requests, typically the last entry
      AutomatikaWeb.Endpoint,
      Automatika.Supervisor,
      TzWorld.Backend.DetsWithIndexCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Automatika.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AutomatikaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
