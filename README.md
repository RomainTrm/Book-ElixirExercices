# Programming Elixir >= 1.6

Notes and code exercises from [Programming Elixir >= 1.6](https://pragprog.com/book/elixir16/programming-elixir-1-6).

## Contents

[1. Take the red pill](./1-TakeTheRedPill/index.md)  
[2. Pattern matching](./2-PatternMatching/index.md)  
[3. Immutability](./3-Immutability/index.md)  
[4. Elixir basics](./4-ElixirBasics/index.md)  
[5. Anonymous functions](./5-AnonymousFunctions/index.md)  
[6. Modules and named functions](./6-ModulesAndNamedFunctions/index.md)  
[7. Lists and recursion](./7-ListsAndRecursion/index.md)  
[8. Maps, Keyword lists, Sets and Structs](./8-MapsKeywordListsSetsAndStructs/index.md)  
[9. An aside - What are types?](./9-AnAside-WhatAreTypes/index.md)  
[10. Processing collections - Enum and Stream](./10-ProcessingCollections-EnumAndStream/index.md)  
[11. Strings and Binaries](./11-StringsAndBinaries/index.md)  
[12. Control flow](./12-ControlFlow/index.md)  
[13. Organizing a project](./13-OrganizingAProject/index.md)  
[14. Tooling](./14-Tooling/index.md)  
[15. Working with multiple processes](./15-WorkingWithMultipleProcesses/index.md)  
[16. Nodes - The key to distributing services](./16-Nodes/index.md)  
[17. OTP: Servers](./17-OTP-Servers/index.md)  
[18. OTP: Supervisors](./18-OTP-Supervisors/index.md)  
[19. A more complex example](./19-MoreComplexExample/index.md)  
[20. OPT: Applications](./20-OTP-Application/index.md)  
[21. Tasks and Agents](./21-TasksAndAgents/index.md)  
[22. Macros and code evaluation](./22-MacrosAndCodeEvaluation/index.md)  
[23. Linking modules: Behavio(u)rs and use](./23-LinkingModules-BehavioursAndUse/index.md)  
[24. Protocols - Polymorphic functions](./24-Protocols-PolymorphicFunctions/index.md)  
[25. More cool stuff](./25-MoreCoolStuff/index.md)  
[Appendix 1. Exceptions: raise and try, catch and throw](./A1-ExceptionsRaiseAndTryCatchAndThrow/index.md)  
[Appendix 2. Type specifications and type checking](./A2-TypeSpecificationsAnTypeChecking/index.md)

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
