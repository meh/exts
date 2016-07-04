defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.3.2",
      deps:    deps,
      package: package,
      description: "ets wrapper" ]
  end

  defp deps do
    [ { :datastructures, "~> 0.2" },
      { :ex_doc, "~> 0.11", only: [:dev] } ]
  end

  defp package do
    [ maintainers: ["meh"],
      licenses: ["WTFPL"],
      links: %{"GitHub" => "https://github.com/meh/exts"} ]
  end
end
