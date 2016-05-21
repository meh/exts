defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.3.0",
      package: package,
      deps:    deps,
      description: "ets wrapper for Elixir" ]
  end

  defp deps do
    [ { :datastructures, "~> 0.1" },
      { :ex_doc, "~> 0.11", only: [:dev] } ]
  end

  defp package do
    [ contributors: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/exts"} ]
  end
end
