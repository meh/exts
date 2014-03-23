defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.0.1",
      elixir: "~> 0.12.3",
      deps: deps ]
  end

  def application do
    if System.get_env("ELIXIR_NO_NIF") do
      []
    else
      [ applications: [:datastructures, :finalizer],
        mod: { Exts, [] } ]
    end
  end

  defp deps do
    if System.get_env("ELIXIR_NO_NIF") do
      [ { :datastructures, github: "meh/elixir-datastructures" } ]
    else
      [ { :finalizer,      github: "meh/elixir-finalizer" },
        { :datastructures, github: "meh/elixir-datastructures" } ]
    end
  end
end
