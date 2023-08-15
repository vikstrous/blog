---
title: "slogevent Go package"
date: 2023-08-15T01:57:26Z
draft: false
---

While attempting to extend the [slog](https://pkg.go.dev/log/slog) package in [many different ways](./extend-slog.md), I kept coming back to this idea that, at some point, I have to write a `slog.Handler`. I don't have a need for high performance, and I just need an easy way to extend my logger to do additional things at the same time as logging. That's why I created [slogevent](https://github.com/vikstrous/slogevent). This Go package makes extending `slog` as simple as writing a function that handles log entries. Here's how you would write your custom log handling with `slogevent`:

```go
func EventHandler(ctx context.Context, e slogevent.Event) {
    if e.Level >= slog.LevelError {
        attrs, _ := json.Marshal(e.Attrs)
        SoundTheAlarm(e.Message, string(attrs))
    }
}
```

Then you hook into slog like this:
```go
slogLogger := slog.New(slogevent.NewHandler(EventHandler, slog.NewTextHandler(os.Stderr, nil)))
```

Try it out [here](https://github.com/vikstrous/slogevent)!
