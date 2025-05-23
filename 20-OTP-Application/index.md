# 20. OPT: Applications

## This is not your father's application

OTP naming convention comes from the Erlang names.  
In OTP, an *application* is a bundle of code that comes with a descriptor (it specifies dependencies, registered global names, and so on). It's more a component or a service than a usual application.  
Though, some *applications* are meant to be run directly.

## The application specification file

When compiling an application, Mix generates a `<project_name>.app` file that is a *application specification* file. It is used to define our application to the runtime environment. It is created automatically from the information in the `mix.exs` file and other information loaded while compiling.  

## Turning our sequence program into an OTP Application

Here we'll modify our sequence program from [chaper 18](../18-OTP-Supervisors/index.md).  

Our `mix.exs` already contains information about our application:  

```elixir
# mix.exs
def application do
  [
    extra_applications: [:logger],
    mod: {
      Sequence.Application, [] # Defines the entry point of the application
    }
  ]
end
```

This says we have a top-level module called `Sequence.Application` that defines a function `start`.  
We can define the initial sequence value here instead of in the `application.ex` file.  

```elixir
# mix.exs
def application do
  [
    extra_applications: [:logger],
    mod: {
      Sequence.Application, 456 # Initial value
    } 
  ]
end
```

```elixir
# lib/sequence/application.ex
def start(_type, initial_number) do
  children = [
    {Sequence.Stash, initial_number}, # Use value passed as parameters
    {Sequence.Server, nil},
  ]

  opts = [strategy: :rest_for_one, name: Sequence.Supervisor]
  Supervisor.start_link(children, opts)
end
```

If we run our application, we've got our new value:  

```elixir
...> iex -S mix
iex> Sequence.Server.next_number
456
```

In the *application* function, `:mod` let us define the entry point of our application.  
We can also add `:registered` to make sure each name is unique across all loaded applications in a node or a cluster.  

```elixir
# mix.exs
def application do
  [
    extra_applications: [:logger],
    mod: {
      Sequence.Application, 456
    },
    registered: [
      Sequence.Server
    ],
  ]
end
```

When compiling, we now have all this information in the `sequence.app` file.  

```elixir
...> mix compile
Generated sequence app
```

```elixir
# _build/dev/lib/sequence/ebin/sequence.app
{application,sequence,
             [{modules,['Elixir.Sequence','Elixir.Sequence.Application',
                        'Elixir.Sequence.Server','Elixir.Sequence.Stash']},
              {optional_applications,[]},
              {applications,[kernel,stdlib,elixir,logger]},
              {description,"sequence"},
              {vsn,"0.1.0"},
              {mod,{'Elixir.Sequence.Application',456}},
              {registered,['Elixir.Sequence.Server']}]}.
```

### More on Application parameters

A better way to inject values into our application is to use a keyword list that can be retrieved anywhere using the `Application.get_env/2` function.  

```elixir
# mix.exs
def application do
  [
    extra_applications: [:logger],
    mod: { Sequence.Application, [] },  # inital value removed
    env: [ initial_number: 456 ], # env variable declared with the initial value
    registered: [ Sequence.Server ],
  ]
end
```

```elixir
# lib/sequence/application.ex
def start(_type, _args) do
  children = [
    {Sequence.Stash, Application.get_env(:sequence, :initial_number)}, # Get value from environment
    {Sequence.Server, nil},
  ]
  
  opts = [strategy: :rest_for_one, name: Sequence.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Releasing your code

A *release* is a bundle containing a version of our application with its dependencies, configuration, etc.  
A *deployment* is a way of getting a *release* into an environment where it can be used.  
A *hot upgrade* is a kind of *deployment* that allows the *release* of a running application to be changed while it continues to run.

## Distillery - The Elixir release manager

*Distillery* is the package used for release management.  
See also [mix release](https://hexdocs.pm/mix/Mix.Tasks.Release.html).

> **Peronal note**: *Distillery* seems not to be maintained anymore, most of the features have been merged into Mix.  
> However *hot upgrade* isn't one of them. See the [documentation](https://hexdocs.pm/mix/1.12/Mix.Tasks.Release.html#module-hot-code-upgrades).  
> Some people suggest having a look at [`castle`](https://hex.pm/packages/castle) but it doesn't do the [`.appup`](https://www.erlang.org/doc/apps/sasl/appup.html) generation. See also the [appup cookbook](https://www.erlang.org/doc/system/appup_cookbook.html)

### Before we start

In Elixir, we version both application code and the data. We can produce several code release without changing any data structure.  
Code version is stored in the `project` dictionary in `mix.exs`.  
In an OTP application, states are maintained by servers and as each server's state is independent, it makes sense version application's data within each server.  

For now let's just set the version of the sate data in our server by using the `@vsn` directive:  

```elixir
# distillery/sequence_v0/lib/sequence/server.ex
defmodule Sequence.Server do
  use GenServer

  @vsn "0"

  # ...
```

### Your first release

First, let's add *distillery* to our project:  

```elixir
# distillery/sequence_v0/mix.exs
defp deps do
  [
    {:distillery, "~> 1.5", runtime: false},
  ]
end
```

Then build and package our application:

```elixir
# Get and compile dependencies
...> mix do deps.get, deps.compile
Resolving Hex dependencies...
Resolution completed in 0.052s
New:
  artificery 0.4.3
  distillery 2.1.1
* Getting distillery (Hex package)
* Getting artificery (Hex package)
Generated distillery app

# Create a release
...> mix release.init
* creating rel/vm.args.eex
* creating rel/remote.vm.args.eex
* creating rel/env.sh.eex
* creating rel/env.bat.eex

# Build the release
...> MIX_ENV=prod mix # Unix-like
# Windows specific command, runs only with a CMD, not on my powershell terminal...
...> set "MIX_ENV=prod" && mix release 
* assembling sequence-0.1.0 on MIX_ENV=prod
* skipping runtime configuration (config/runtime.exs not found)
* creating _build/prod/rel/sequence/releases/0.1.0/vm.args
* creating _build/prod/rel/sequence/releases/0.1.0/remote.vm.args
* creating _build/prod/rel/sequence/releases/0.1.0/env.sh
* creating _build/prod/rel/sequence/releases/0.1.0/env.ba

Release created at _build/prod/rel/sequence

    # To start your system
    _build/prod/rel/sequence/bin/sequence start

Once the release is running:

    # To connect to it remotely
    _build/prod/rel/sequence/bin/sequence remote

    # To stop it gracefully (you may also send SIGINT/SIGTERM)
    _build/prod/rel/sequence/bin/sequence stop

To list all commands:

    _build/prod/rel/sequence/bin/sequence
```

Our application is now packages in the `_build/prod/rel/sequence/releases` directory under the version 0.1.0.  

#### Deploy and run the app

```elixir
# To start with an iex session attached
_build/prod/rel/sequence/bin> sequence start_iex
iex> Sequence.Server.next_number
456
iex> Sequence.Server.next_number
457
```

We leave this IEx session running.  

#### A second release

In a second version of our application, we change the behavior of the server and we increment the application's version:  

```elixir
# distillery/sequence_v1/lib/sequence/server.ex
def next_number do
  number = GenServer.call __MODULE__, :next_number
  "The next number is #{number}"
end
```

```elixir
# distillery/sequence_v1/mix.exs
def project do
  [
    app: :sequence,
    version: "0.2.0", # Version updated
    elixir: "~> 1.18",
    start_permanent: Mix.env() == :prod,
    deps: deps()
  ]
end
```

We don't change the `@vsn` as the server's data representation is not affected.  
Now, instead of packaging a full release, we will produce an *hot upgrade* release.  

> **Personal note**: As it was getting very complicated, I didn't run the following deployment part of demo in my machine.  
> Following deployment commands are **not** supported anymore, this is just to understand the hot upgrade "philosophy".  

```elixir
...> mix release --env=prod --upgrade
```

#### Deploying an Upgrade

First we must copy our new release in a `releases/<version>` subdirectory of the previous release.  
Then run:  

```elixir
...> sequence upgrade 0.2.0
```

If we go back to our previous session, without a restart, we can ask the numbers:  

```elixir
iex> Sequence.Server.next_number
"The next number is 458"
iex> Sequence.Server.next_number
"The next number is 459"
```

We can also downgrade our application:  

```elixir
...> sequence downgrade 0.1.0
```

#### Migrating server state

Now we want to save the delta for the next number. If the delta is 10, each time we call `next_number` we should get an increment of 10.  

First, let's change our server's behavior:  

```elixir
# distillery/sequence_v2/lib/sequence/server.ex
defmodule Sequence.Server do
  use GenServer
  require Logger

  @vsn "1" # Upgrade version

  defmodule State do # Define a struct for the state
    defstruct(current_number: 0, delta: 1)
  end

  #####
  # External API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def next_number do
    number = GenServer.call __MODULE__, :next_number
    "The next number is #{number}"
  end

  def increment_number(delta) do
    GenServer.cast __MODULE__, {:increment_number, delta}
  end

  #####
  # GenServer implementation

  def init(_) do
    state = %State{ current_number: Sequence.Stash.get() }
    { :ok, state }
  end

  def handle_call(:next_number, _from, state = %{current_number: n}) do
    # Get number from the state and apply the correct increment for the next value
    { :reply, n, %{state | current_number: n + state.delta} } 
  end

  def handle_cast({:increment_number, delta}, state) do
    # Store the increment
    { :noreply, %{state | delta: delta} }
  end

  def terminate(_reason, current_number) do
    Sequence.Stash.update(current_number)
  end

end
```

If we run it:  

```elixir
iex> Sequence.Server.next_number
"The next number is 456"
iex> Sequence.Server.next_number
"The next number is 457"
iex> Sequence.Server.increment_number(10)
:ok
iex> Sequence.Server.next_number
"The next number is 458"
iex> Sequence.Server.next_number
"The next number is 468"
```

OTP provides callbacks for state transition:  

```elixir
# distillery/sequence_v2/lib/sequence/server.ex
def code_change("0", old_state = current_number, _extra) do
  new_state = %State{
    current_number: current_number,
    delta: 1
  }
  Logger.info "Changing code from 0 to 1"
  Logger.info inspect(old_state)
  Logger.info inspect(new_state)
  {:ok, new_state}
end
```

Then we update the app version into our `mix.exs` to *0.3.0*, then we run through the same upgrade process.  

## OTP is big - unbelievably big

This (the whole OPT part of this book) was only a small introduction to the OTP. It can include release management, handling of distributed failover, automated scaling and so on.  
