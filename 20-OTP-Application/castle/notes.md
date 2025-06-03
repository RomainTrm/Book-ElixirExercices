La release ne semble pas nécessaire.  

```elixir
# 1er appup
{
  ~c"0.2.0",
    [{~c"0.1.0", [{:load_module, Sequence.Server}]}],
    [{~c"0.1.0", [{:load_module, Sequence.Server}]}]
}
```

Appup structure:  

```erlang
{Vsn,
  [{UpFromVsn, Instructions}, ...],
  [{DownToVsn, Instructions}, ...]}.
```

Appup cookbook: https://www.erlang.org/doc/system/appup_cookbook.html  

compile le appup : `mix compile.appup`
relup: `mix forecastle.relup --target .\_build\dev\rel\sequence\releases\0.2.0\sequence --fromto .\_build\dev\rel\sequence\releases\0.1.0\sequence`

Relup command doc: https://hexdocs.pm/forecastle/0.1.3/Mix.Tasks.Forecastle.Relup.html  

## Tentative  

```elixir
defmodule Sequence.MixProject do
  use Mix.Project

  def project do
    [
      app: :sequence,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
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
    ]
  end
end
```

```elixir
...> mix release.init
...> mix release
...> _build/dev/rel/sequence/bin/sequence start_iex
```

Release with forecastle is missing a `sys.config` file :  

```text
%% coding: utf-8
%% RUNTIME_CONFIG=false
[].
```


```elixir
# Window 1
# V0.1.0
...> mix compile
...> mix release.init
...> mix release

# Window 2
...> .\_build\dev\rel\sequence\bin\sequence start_iex
```
