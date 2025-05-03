# Take the red pill

Elixir is a functional programming language, meaning you (as a developer) write small chunks of code (functions) and then compose them.  
It can be convenient to see functions as data transformers. You process a succession of transformation to achieve your desired goal.  
Elixir also shines at parallelization, it provides a powerful messaging mechanism (thanks to the Erlang machine) that allows millions of processes to run simultaneously on a single machine.

Open iex: `..> iex(.bat)`  
Get help: `iex> h`, 
Get help on a module: `iex> h(Enum)` or `iex> h Enum`  
Get help on a function: `iex> h Enum.map`  

Get information on a value: `iex> i 123`  

Configure iex: `iex> h IEx.configure` (display help)

Run our Hello World:  

- From the terminal: `..> elixir Hello.exs`
- From iex: `iex> c "Hello.exs"`
