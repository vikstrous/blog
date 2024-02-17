---
title: "tstemporal: a type-safe Temporal Go SDK wrapper"
date: 2024-02-16T00:00:00Z
---

Are you using [Temporal](temporal.io) and writing workflows in Go using their Go SDK? If so, I have something for you. Otherwise feel free to skip this blog post.

I created a type-safe wrapper around the Temporal Go SDK called [tstemporal](https://github.com/vikstrous/tstemporal). It helps you avoid many common mistakes when working with Temporal workflows.

The native SDK is powerful and flexible. Although this wrapper sacrifices some power and flexibility, it offers safety through its opinionated design.

Workers:

* Have all the right activities and workflows registered before starting

Activities:

* Are called on the right namespace and queue
* Are called with the right parameter types
* Return the right response types
* Registered functions match the right type signature

Workflows:

* Are called on the right namespace and queue
* Are called with the right parameter types
* Return the right response types
* Registered functions match the right type signature

Schedules:

* Set arguments with the right types
* Can be 'set' upon application startup, automatically applying the intended effect to the schedule's state on the cluster

Queries and updates:

* Are called with the right types
* Return the right types
* Registered functions match the right type signature

This is a pretty nice list, so I think it's worth considering when building something new. I also believe it helps organize code better.

Take a look at some example usage of this library:

```go
package main

import (
    "context"
    "fmt"
    "time"

    "github.com/vikstrous/tstemporal"
    "go.temporal.io/sdk/client"
    "go.temporal.io/sdk/worker"
    "go.temporal.io/sdk/workflow"
)

// Define a new namespace and task queue.
var nsDefault = tstemporal.NewNamespace(client.DefaultNamespace)
var queueMain = tstemporal.NewQueue(nsDefault, "main")

// Define a workflow with no parameters and no return.
var workflowTypeHello = tstemporal.NewWorkflow[struct{}, struct{}](queueMain, "HelloWorkflow")

// Define an activity with no parameters and no return.
var activityTypeHello = tstemporal.NewActivity[struct{}, struct{}](queueMain, "HelloActivity")

func main() {
    // Create a new client connected to the Temporal server.
    c, err := tstemporal.Dial(client.Options{})
    if err != nil {
        panic(err)
    }
    defer c.Close()

    // Register the workflow and activity in a new worker.
    wrk, err := tstemporal.NewWorker(queueMain, []tstemporal.Registerable{
        workflowTypeHello.WithImplementation(helloWorkflow),
        activityTypeHello.WithImplementation(helloActivity),
    })
    if err != nil {
        panic(err)
    }
    ctx := context.Background()
    ctx, cancel := context.WithCancel(ctx)
    defer cancel()
    go func() {
        err = wrk.Run(ctx, c, worker.Options{})
        if err != nil {
            panic(err)
        }
    }()

    // Execute the workflow and wait for it to complete.
    _, err = workflowTypeHello.Run(ctx, c, client.StartWorkflowOptions{}, struct{}{})
    if err != nil {
        panic(err)
    }

    fmt.Println("Workflow completed.")
}

// helloWorkflow is a workflow function that calls the HelloActivity.
func helloWorkflow(ctx workflow.Context, _ struct{}) (struct{}, error) {
    ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
        StartToCloseTimeout: time.Second * 10,
    })
    return activityTypeHello.Run(ctx, struct{}{})
}

// helloActivity is an activity function that prints "Hello, Temporal!".
func helloActivity(ctx context.Context, _ struct{}) (struct{}, error) {
    fmt.Println("Hello, Temporal!")
    return struct{}{}, nil
}
```

Be warned that in this first iteration not all temporal features are easily accessible and there are no escape hatches from the safety. I highly recommend it when starting a new project or service, but it may be difficult to retrofit into existing services if they use the full power of temporal. I'm looking for feedback on how to allow for incremental adoption and how to support more of temporal's features.

If you are ready to try it anyway, head over to https://github.com/vikstrous/tstemporal!