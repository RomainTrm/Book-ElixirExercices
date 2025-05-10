# 13. Organizing a project

## Set 1: Use Mix to create our new project

Mix is a command-line utility that manages Elixir projects.  

```elixir
...> mix help
mix                   # Runs the default task (current: "mix run")
mix app.config        # Configures all registered apps
mix app.start         # Starts all registered apps
...
mix run               # Runs the current application
mix test              # Runs a project's tests
mix test.coverage     # Build report from exported test coverage
mix xref              # Prints cross reference information
iex -S mix            # Starts IEx and runs the default task
```

We can also ask for help for a specific command: `mix help <cmd>`.

### Create the project tree

To create a new project, use `mix new <project_name>`.  
In a new project, we find  

- `.formater.exs`: Configuration use by the source code formatter.
- `.gitignore`
- `README.md`
- `config/`: directory where we'll put some application-specific configuration.
- `lib/`: contains the code source of our application, it already contains a top-level module.
- `mix.exs`: project configuration options used by Mix.
- `test/`: contains unit tests of our application.

## Transformation: parse the command line

For CLI applications, Elixir conventions says it starts with a function `run` placed in a module `<Project_Name>.Cli`. This module is itself placed into a directory `lib/<project_name>/cli.ex`.  

```goat
Example for the project *issues*

lib
+-+ issues
| +- cli.ex
+- issues.ex
```

## Write some basic tests

There is an available testing framework called ExUnit. See [documenation](https://hexdocs.pm/ex_unit/main/ExUnit.html).  

```elixir
defmodule IssuesTest do
  use ExUnit.Case
  doctest Issues

  test "greet the world" do
    assert Issues.hello() == :world
  end
end
```

Use `mix test` command to run our tests.  

## Transformation: fetch from GitHub

We can run our CLI application using mix: `mix run -e 'Issues.CLI.run(["-h"])'`.  
We can also load the project into iex with `iex -S mix`.

## Step 2: use libraries

We can find libraries on [hex.pm](https://hex.pm/).  
To add a library, we have to modify our `mix.exs` file. For example, let's add the library "httpoison":  

```elixir
  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.6"}
    ]
  end
```

Then run `mix deps` to see dependencies status and `mix deps.get` to install them.  

## Transformation: convert response

### Application configuration

We can define environment variables in our configuration. For example, in our *issues* project we define a *github_url* variable.  
In our `config/config.exs` file:  

```elixir
use Mix.Config
config :issues, github_url: "https://api.github.com"
```

Then we can access it in our application:  

```elixir
@github_url Application.get_env(:issues, :github_url)

def issues_url(user, project) do
  "#{@github_url}/repos/#{user}/#{project}/issues"
end 
```

Note: we can change config depending on the environment, see [`import_config`](https://hexdocs.pm/elixir/main/Config.html#import_config/1).  

## Step 3: Make a command-line executable

To package our application to be run without using Mix, we first have to define our entry point.  

In the `mix.exs` file, we must use the *escript* utility:  

```elixir
def project do
  [
    app: :issues,
    # Add escript
    escript: escript_config(),
    version: "0.1.0",
    elixir: "~> 1.9",
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]
end

# ...

# add escript_config
defp escript_config do
  [
    main_module: Issues.CLI
  ]
end
```

Now in the `lib/issues/cli.ex` file we must rename our `run` function to `main`.  
To package our application, run `mix escript.build`.  

## Step 4: Add some logging

Default `mix.exs` starts the logger:  

```elixir
def application do
  [
    extra_applications: [:logger]
  ]
end
```

We can configure the level of messages we want to log, available levels in order of severity: `debug`, `info`, `warn`, `error`.  
We can define the minimum level of logging to include in our `config/config.exs` file:  

```elixir
use Mix.Config

# ...

config :logger, compile_time_purge_level: :info
```  

To log something, use the `Logger` module in the code, functions are `Logger.debug`, `.info`, `.warn` and `.error`.  

## Step 5: Create project documentation

To generate code documentation, we have [ExDoc](https://hexdocs.pm/ex_doc/readme.html) available.  
Add it to the `mix.exs` with an output formatter (here *earmark*):  

```elixir
# Run "mix help deps" to learn about dependencies.
defp deps do
  [
    {:httpoison, "~> 1.6"},
    {:poison, "~> 4.0"},
    {:ex_doc, "~> 0.21.2"},
    {:earmark, "~> 1.4"},
    {:excoveralls, "~> 0.12.1", only: :test}
  ]
end
```

To generate documentation, run `mix docs`.
