# Programming Elixir >= 1.6

Code exercises from [Programming Elixir >= 1.6](https://pragprog.com/book/elixir16/programming-elixir-1-6) coded while reading the book.

## Useful commands

Run code from the terminal: `..> elixir(.bat) MyModule.exs` 

### IEX

Open iex: `..> iex(.bat)`  
Load a module in iex: `iex> c "MyModule.exs"`  
Get help: `iex> h`, you can specify a module or even a function.  

More details [here](/1-TakeTheRedPill/index.md)

### Mix

Display help: `..> mix help`  
Create a project: `..> mix new <projectName>`  
Load dependencies (you can find dependencies on [hex](https://hex.pm/) website): `..> mix deps.get`  
Compile: `..> mix compile`  
Run tests: `..> mix test`  
Run in interactive mode: `..> iex -S mix`  

Check [elixirschool](https://elixirschool.com/en/lessons/basics/mix/) for more infos.  
