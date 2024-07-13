---
title: "Achieve Cleaner Code by Avoiding Global State"
date: 2024-07-12T00:00:00Z
draft: false
---

### Introduction

Let's talk about global state in programming. We've all made excuses for using it, but there are better ways. Here, we'll address some common excuses and show why avoiding global state is a game-changer.

### Common Excuses for Using Global State

* **"I'll use this code only in this specific way."**
   Code often outgrows its initial purpose, leading to unexpected issues.

* **"It's just the logger, though!"**
   Even a logger can introduce hidden dependencies and headaches.

* **"I don't have time to structure this correctly!"**
   Shortcuts now can mean big problems later.

* **"We can still unit test this by modifying the global state."**
   This leads to fragile, hard-to-maintain tests.

* **"This one dependency I'm using requires it."**
   Dependencies can often be replaced or wrapped.

* **"It's just a CLI. There's only ever one instance of it, so who cares!"**
   Single-instance applications can still suffer from unpredictable behavior.

### Benefits of Avoiding Global State

Let's take a look at what happens when you don't use global state.

#### Composability

If a function modifies its input or produces new output, it can be run against multiple copies of that input and composed with other functions to process data in new ways. Functions that interact with each other through global state have limited composability.

#### Clarity and Predictability

Functions that rely only on their inputs are easier to understand. If a struct doesn't have a random number generator, it's deterministic. No logger? No logging surprises.

#### Easier Testing

Without global state, tests are simpler and more reliable. You can run tests concurrently and use mock objects easily. Tests can be sped up by just adding more hardware.

#### Better Resource Management

Avoiding global state means managing resources better. An HTTP client created in a test will be properly shut down, preventing leaks and leftover processes.

#### Clean Process Termination

Centralizing environment variables and config files ensures clean exits. Metrics, traces, and logs are all handled before shutdown.

#### Simplified Debugging

Debugging is easier without global state. Issues are more predictable, and resource leaks are easier to find and fix.

### Conclusion

Avoiding global state brings clarity, better testing, resource management, and simpler debugging. The short-term convenience isn't worth the long-term trouble.

### Call to Action

Ever dealt with global state headaches? Share your stories! For more insights, check out Dave Cheney’s 2017 blog post [here](https://dave.cheney.net/2017/06/11/go-without-package-scoped-variables).