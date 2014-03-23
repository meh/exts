defmodule Exts.Supervisor do
  use Supervisor.Behaviour

  def start_link do
    :supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Exts.Manager, [])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
