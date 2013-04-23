#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Manager do
  use Application.Behaviour
  use GenServer.Behaviour

  def start(_, _) do
    if pid = Process.whereis(__MODULE__) do
      { :ok, pid }
    else
      case :gen_server.start_link(__MODULE__, [], []) do
        { :ok, pid } = r ->
          Process.register(pid, __MODULE__)
          r

        r -> r
      end
    end
  end

  def stop(_) do
    Process.exit(Process.whereis(__MODULE__), "application stopped")
  end

  def handle_call({ :own, id, pid }, state) do
    { :reply, :ets.give_away(id, pid, nil), List.delete(state, id) }
  end

  def handle_info({ :destroy, table }, state) do
    :ets.delete(table)

    { :noreply, List.delete(state, table) }
  end

  def handle_info({ :'ETS-TRANSFER', table, _from, _data }, state) do
    { :noreply, [table | state] }
  end
end
