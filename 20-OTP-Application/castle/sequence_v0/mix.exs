defmodule Sequence.MixProject do
  use Mix.Project

  def project do
    [
      app: :sequence,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:castle, "~> 0.3.0"},
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
end
