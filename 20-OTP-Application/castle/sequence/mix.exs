defmodule Sequence.MixProject do
  use Mix.Project

  def project do
    [
      app: :sequence,
      version: "0.1.0",
      # version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :dev,
      deps: deps(),
      releases: releases(),
      # appup: "appup.ex", # Relative to the project root.
      # compilers: Mix.compilers() ++ [:appup],
    ]
  end

  defp releases do
    [
      sequence: [
        include_executables_for: [:windows],
        steps: [&Forecastle.pre_assemble/1, :assemble, &Forecastle.post_assemble/1]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {
        Sequence.Application, 456
      },
      registered: [
        Sequence.Server,
      ],
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      {:castle, "~> 0.3.1"},
      {:forecastle, "~> 0.1.3"},
    ]
  end
end
