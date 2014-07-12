#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                    Version 2, December 2004
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
#  0. You just DO WHAT THE FUCK YOU WANT TO.

defprotocol Exts.Selection do
  def next(self)
  def values(self)
end

defimpl Exts.Selection, for: Atom do
  def next(nil) do
    nil
  end

  def values(nil) do
    []
  end
end
