# 16. Nodes - The key to distributing services

A *node* is a running Erlang VM (a *Beam* instance). Nodes can connect to each other in the same computer or across a network.  

## Naming nodes

We can setup names to our nodes:  

```elixir
iex> Node.self
:nonode@nohost
...> iex --name wibble@light-boy.local
iex(wibble@light-boy.local)> Node.self
:"wibble@light-boy.local"
...> iex --sname wobble
iex(wobble@DESKTOP-....)>
```

We can connect to nodes:  

```elixir
# Window 1
...> iex --sname node_one
iex(node_one@machine-name)>

# Window 2
...>iex --sname node_two
iex(node_two@machine-name)> Node.list
[]
iex(node_two@machine-name)> Node.connect :"node_one@machine-name"
true
iex(node_two@machine-name)> Node.list
[:"node_one@machine-name"]

# Window 1
iex(node_one@machine-name)> Node.list
[:"node_two@machine-name"]
```

We can then run code from both nodes:  

```elixir
# Window 1
iex(node_one@machine-name)> func = fn -> IO.inspect Node.self end
#Function<43.81571850/0 in :erl_eval.expr/6>
# => This function returns information about the Node that runs it

iex(node_one@machine-name)> spawn(func)
:"node_one@machine-name"
# => Runs on node one

iex(node_one@machine-name)> Node.spawn :"node_one@machine-name", func
:"node_one@machine-name"
#PID<0.116.0>
# => Runs on node one

iex(node_one@machine-name)> Node.spawn :"node_two@machine-name", func
:"node_two@machine-name"
#PID<13771.116.0>
# => Runs on node two, first field of the return PID isn't zero, meaning we are not running the code on the local node
# => As func has been defined on node one, it uses IO of node one
```

### Nodes, cookies and security

For security reasons, nodes compare their cookies at connection before connecting to each other:  

```elixir
# Window 1
...> iex --sname node_one --cookie cookie-one
iex(node_one@machine-name)>

# Window 2
...> iex --sname node_two --cookie cookie-two
iex(node_two@machine-name)> Node.connect :"node_one@machine-name"
false

# Window 1
13:17:19.042 [error] ** Connection attempt from node :"node_two@machine-name" rejected. Invalid challenge reply. **
```

Note: when no cookies are specified, Erlang creates its own and stores it. These are then shared for all nodes of a given machine, that's why they're not mandatory for a local machine.  

**Warning**: when connecting nodes in a network, be aware cookies are transmitted in plain text.  

## Naming your processes

When can register a PID under a name using `:global.register_name(name, pid)`, then we can retrieve the PID using `:global.whereis_name(name)`.  
Theses are shared across all nodes, an example is available [here](Nodes-2.exs).  

```elixir
# Window 1
...> iex --sname one
iex(one@machine-name)> c("Nodes-2.exs")
[Client, Timer]

# Window 2
...> iex --sname two
iex(two@machine-name)>

# Window 1
iex(one@machine-name)> Node.connect :"two@machine-name"
true
iex(one@machine-name)> Timer.start
:yes
tick
tick
iex(one@machine-name)> Client.start
registering #PID<0.127.0>
{:register, #PID<0.127.0>}
tick
tock
tick
tock    

# Window 2
iex(two@machine-name)> c("Nodes-2.exs")
[Client, Timer]
iex(two@machine-name)> Client.start
{:register, #PID<0.124.0>}
tock
tock
```

## Input, output, PIDs and nodes

In Elixir, we identify an open file or device by the PID of tis I/O server.  
Default device it uses is returned by the function `:erlang.group_leader`.  

```elixir
# Window 1
...> iex --sname one
iex(one@machine-name)>

# Window 2
...> iex --sname two
iex(two@machine-name)> Node.connect :"one@machine-name"
true
iex(two@machine-name)> :global.register_name(:two, :erlang.group_leader)
:yes

# Window 1
iex(one@machine-name)> two = :global.whereis_name :two
#PID<13771.76.0>
iex(one@machine-name)> IO.puts(two, "Hello world")
:ok

# Window 2
Hello world
iex(two@machine-name)>
```
