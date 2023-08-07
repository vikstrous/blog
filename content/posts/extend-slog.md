---
title: "Four ways to extend the go 1.21 slog Logger"
date: 2023-08-06T00:00:00Z
draft: true
---

In my [previous blog post](https://medium.com/anchorage/three-logging-features-to-improve-your-slog-f72300a7fb66) on the Anchorage Digital blog, I wrote about logging features I'd love to see built around the new slog package coming in Go 1.21. I heard from several people that they want to learn more about how exactly to do this. To answer these questions, I built out 6 examples of how to extend slog, showing 4 different strategies. I used some of the use-cases from the last blog post. The example code and detailed explanations can be found [here](https://github.com/vikstrous/slogexamples/). Feel free to copy-paste and modify any of these examples.

During the process, I learned a lot about writing allocation-free Go code because the slog code base is full of performance optimizations. This led me to file an issue about a [potential performance improvement](https://github.com/golang/go/issues/61774). I'm very impressed with slog so far and I hope that these examples help others adopt it by making extending it easier.

Continue reading [here](https://github.com/vikstrous/slogexamples/)!