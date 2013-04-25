#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.Manager do
  @moduledoc """
  This module manages smart garbage collection for ets tables.
  """

  use Application.Behaviour
  use GenServer.Behaviour

  @doc """
  Start the manager, if it's already started it will just return the original
  process.
  """
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

  @doc """
  Stop the manager, killing the process, keep in mind this will terminate the
  managed tables too.
  """
  def stop(_) do
    Process.exit(Process.whereis(__MODULE__), "application stopped")
  end

  @doc """
  Handle a call to reown the table.
  """
  def handle_call({ :own, id, pid }, state) do
    { :reply, :ets.give_away(id, pid, nil), List.delete(state, id) }
  end

  @doc """
  Handle the finalization.
  """
  def handle_info({ :destroy, table }, state) do
    :ets.delete(table)

    { :noreply, List.delete(state, table) }
  end

  @doc """
  Handle a table transfer.
  """
  def handle_info({ :'ETS-TRANSFER', table, _from, _data }, state) do
    { :noreply, [table | state] }
  end
end
