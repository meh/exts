defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.1.1-dev",
      elixir: "~> 0.13.2-dev",
      package: package,
      description: "ets wrapper for Elixir" ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: [ { "GitHub", "https://github.com/meh/exts" } ] ]
  end
end
