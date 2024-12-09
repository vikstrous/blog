---
title: "Migrate workflows with positional arguments to Tempts easily"
date: 2024-12-09T00:00:00Z
---

[Tempts](https://github.com/vikstrous/tempts) is my [temporal](https://temporal.io/) [Go](https://go.dev/) [SDK](https://github.com/temporalio/sdk-go) wrapper that enables safer usage of Temporal when writing workflows in Go. I've been using Tempts successfully for new code, but I found it difficult to migrate existing code that uses positional arguments rather than a single input object. The new version of Tempts makes this migration easy and provides an easy way to move away from positional arguments after migrating to Tempts.

## The problem with positional arguments

Positional arguments are when your workflow or activity's function signature looks like `func(ctx context.Context, param1 string, param2 string)` rather than `func(ctx context.Context, params ParamType)`. The single input object pattern makes it easier to add and remove input parameters. With positional arguments, you can add parameters only to the end and can't remove any without creating a new activity/workflow name. This is why Tempts originally didn't support positional arguments at all.

## Introducing `NewWorkflowPositional` and `NewActivityPositional`

Tempts originally supported only a single input object, but this made it difficult to apply to existing workflows because positional arguments are present in many codebases. With the latest version of Tempts, there's a pair of functions: `NewWorkflowPositional` and `NewActivityPositional` that enable this in a way that helps you transition to single input objects more easily in the future.

These functions allow you to register an activity or workflow exactly the same way as regular Tempts, but each of the input object's fields is actually treated as a positional argument.

## Migrating positional argument workflows to Tempts

Let's take a look at how to migrate workflows or activities with positional arguments to Tempts. Consider the following code using the Temporal SDK directly:

```go
func HelloWorkflow(ctx workflow.Context, 
    name string,
    greeting string,
) (string, error) {
	return greeting + ", " + name + "!", nil
}

// In your application code:
var output string
temporalClient.ExecuteWorkflow(ctx, client.StartWorkflowOptions{}, "HelloWorkflow",
    "Viktor",
    "Hello",
).Get(ctx, &output)
```

Now, to use Tempts, you can define and call your workflow as follows:

```go
type HelloParams struct {
  Name     string
  Greeting string
}
func HelloWorkflow(ctx workflow.Context, params HelloParams) (string, error) {
	return params.Greeting + ", " + params.Name + "!", nil
}
var Hello = tempts.NewWorkflowPositional[HelloParams, string](queueMain, "Hello")

// In your application code:
Hello.Run(ctx, temporalClient, client.StartWorkflowOptions{}, HelloParams{
  Name:     "Viktor",
  Greeting: "Hello",
})
```

Notice the use of `NewWorkflowPositional` instead of `NewWorkflow`. This is what allows you to introduce Tempts into this code without any breaking changes to the workflow's API.

## Migrating away from positional arguments with Tempts

After adopting Tempts, you should switch away from positional arguments to get the full benefits of Tempts and reduce the chance of human error when modifying the input type. To do that, introduce a new workflow definition with a different name and with `NewWorkflow` instead of `NewWorkflowPositional`:

```go
var Hello2 = tempts.NewWorkflow[HelloParams, string](queueMain, "Hello2")
```

Then you have to migrate your application code to call `Hello2` by simply changing the workflow definition being used at every call site, and after all old workflows have completed, you can delete `Hello`. This strategy really simplifies the migration to the single input object pattern.

Tempts is easier than ever to adopt now that positional arguments can be handled with `NewWorkflowPositional`/`NewActivityPositional`. Read more about the benefits of Tempts and try it out by following the instructions on [GitHub](https://github.com/vikstrous/tempts). If you use or want to try Tempts and run into any issues, open an issue on [GitHub](https://github.com/vikstrous/tempts/issues)!