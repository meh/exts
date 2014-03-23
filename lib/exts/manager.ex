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

  use GenServer.Behaviour

  def start_link(_args \\ []) do
    :gen_server.start_link({ :local, :exts }, __MODULE__, [], [])
  end

  @doc """
  Handle a call to reown the table.
  """
  def handle_call({ :own, id, pid }, state) do
    { :reply, :ets.give_away(id, pid, nil), List.delete(state, id) }
  end

  @doc """
  Handle the finalization and table transfer.
  """
  def handle_info({ :destroy, table }, state) do
    :ets.delete(table)

    { :noreply, List.delete(state, table) }
  end

  def handle_info({ :'ETS-TRANSFER', table, _from, _data }, state) do
    { :noreply, [table | state] }
  end
end
