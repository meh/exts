#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defmodule Exts.FileError do
  @moduledoc """
  Exception thrown if an error occurs on loading or dumping a table.
  """

  defexception message: nil

  def exception(reason: { :file_error, path, :enoent }) do
    %__MODULE__{message: to_string(path) <> " doesn't exist"}
  end
end
