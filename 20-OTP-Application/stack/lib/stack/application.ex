defmodule Stack.Application do
  @moduledoc false

  use Application

  def start(_type, initial_stack) do
    children = [
      {Stack.Stash, initial_stack},
      {Stack.Server, nil}
    ]

    opts = [strategy: :rest_for_one, name: Stack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
