# 19. A more complex example

We should ask ourselves how to organize the code of software. The author suggests five questions to drive our thinking.  
Careful though, this is not a methodology.

## Introdution to Duper

In this chapter, the author suggests an app called Duper: a software that scans files in a directory tree, compute hashes and report duplicates.  

### Q1: What is the environment and what are the constraints?  

On what device and/or network are we running our application? What are the limitations?  
For our example, it will be on a computer. The main limitation will be the available memory, especially when computing hashes for large files.

### Q2: What are the focal points?

Focal points are responsibilities of the application.  
In Duper, we can identify:  

- gather and store results
- traverse the file system and return file path
- compute files' hashes
- orchestrate all these operations in a concurrent way

### Q3: What are the runtime characteristics?

This is how the workload will be distributed across the system and what strategy to setup for efficient use of resources.  
In our example, the hash computation will be a bottleneck, especially for large files. If we use a single worker for this job, the rest of the application will be idle most of the time. If we have too many workers, we risk running out of memory.  
Even more, we can't distribute files evenly to workers as one can get mainly small files and the other mainly large files.  
In our case, workers will ask for the next file when they're available for another hash computation.  

### Q4: What do I protect from errors?

What parts of the systems are critical?  
For Duper, this is the result we don't want to lose.  

### Q5: How do I get this thing running?

What are the dependencies between my servers? In which order should I start them?  
For Duper:  

- Worker depends on PathFinder and Gatherer
- Gatherer depends on Results and the worker supervisor
- PathFinder and Results depend on nothing

## The Duper application

Complete application code is available [here](./duper/).  

### The Results server

We write a server that store files paths for a hash. We also provide a second function that returns file paths for duplicated files (files with the same hash).  

### The PathFinder server

For this server, we import the [*dir_walker*](https://hexdocs.pm/dir_walker/api-reference.html) dependency in our `mix.exs` for accessing our file system.  
`DirWalker` is a server, we encaspulate it into our `PathFinder` that exposes a function `next_path`.  

### The Worker Supervisor

This supervisor only manages workers servers. We use `DynamicSupervior` that allows us to create an arbitrary number of workers at runtime.  

#### Thinking about supervision strategies

When adding a child to a supervisor, we should ask ourselves how do we want to handle errors and work resuming?  
For the `WorkerSupervisor`, we choose to consider a failure as an application failure and stop. As the same goes for the `Results` and the `PathFinder` servers, we can change the strategy in our `application.ex` for a `:one_for_all`.  

### The Gatherer server

This server is responsible for the orchestration and the lifecycle of the application: starting the workers and returning the results to the user.  
As we can't start workers in the `init` function as they can be initialized before our `Gatherer`, in such case the messages they will send the `Gatherer` may well get lost. To avoid this issue, we send to ourselves the `:kick_off` command using the `Process.send_after/3` function. It will be executed once our server is initialized.  

### What about the Workers?

`Workers` have no incoming API, once spawned, they ask for a path, compute the hash and send the result to the `Gatherer`. If there is no path left, it sends a `:done` notification to the `Gatherer` then stops.  

> Note: we could implement a loop using recursion, but instead the server sends a message to itself. The reason lies in the Elixir runtime: a server holding the CPU for too much time (5 seconds by default) is assumed to be in timeout and is then terminated. By sending new messages, we release the CPU and reset the counter.

The server is flagged as `:transient`, meaning it's supposed to stop at some point and should not be restarted under normal conditions.

## But does it work?

To run our application, we have to use `mix run --no-halt`. By default, `mix run` start the application and exists. The `--no-halt` tells mix not to exit and wait for returns from the application.  

### Let's play with timing

We can change the number of workers to run in parallel, first we should observe improvement on the duration of a directory analysis. At some point though, there will be too many processes running in parallel in regard to the computer hardware, hitting a bottleneck like the available memory or the number of cores in the CPU.  
