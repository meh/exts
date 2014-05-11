defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.1.1",
      elixir: "~> 0.13.2",
      package: package,
      description: "ets wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh"],
      license: "WTFPL",
      links: [ { "GitHub", "https://github.com/meh/exts" } ] ]
  end
end
