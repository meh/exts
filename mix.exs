defmodule Exts.Mixfile do
  use Mix.Project

  def project do
    [ app: :exts,
      version: "0.0.1",
      elixir: "~> 0.12.3",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    if System.get_env("ELIXIR_NO_NIF") do
      []
    else
      [ applications: [:finalizer],
        mod: { Exts.Manager, [] } ]
    end
  end

  # Returns the list of dependencies in the format:
  # { :foobar, "0.1", git: "https://github.com/elixir-lang/foobar.git" }
  defp deps do
    if System.get_env("ELIXIR_NO_NIF") do
      [ { :datastructures, github: "meh/elixir-datastructures" } ]
    else
      [ { :finalizer, github: "meh/elixir-finalizer" },
        { :datastructures, github: "meh/elixir-datastructures" } ]
    end
  end
end
