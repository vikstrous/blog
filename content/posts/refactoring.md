---
title: "How to break up a large code refactor"
date: 2025-02-13T00:00:00Z
draft: false
---

If you, like me, like to keep your code clean, then you probably need to do many refactors. I work in a monorepo with many services and this gives me a lot of flexibility for how to refactor code. I’ve done this many times over the years and I’ve found that breaking up refactors into incremental steps is key to completing them. Trying to do everything at once might seem faster, but I’ve seen too many refactors stall for months, unable to merge. Here’s how to be successful with your next refactor.

## The process

This three step process will help your refactor get merged.

### 1. Proof of concept

The first thing you should do when you start a refactor is to do some sort of proof of concept. You don’t merge this change. You might add a copy of the thing you are refactoring and use it in one place, or you might add a check for an invariant and confirm that all tests still pass. You might change a type or remove a field or method and confirm that things still compile. Just make sure that what you are doing is better.

### 2. Feedback

You might also want to get input at this stage so that your refactor is accepted later by other engineers. Nothing feels worse than working on a change for months just for someone to point out that there’s a good reason for it to not be merged. After you’ve proven that your change is good and works, move on to making the real changes.

### 3. Change one thing at a time

Your goal might be to add 10 new methods, change one type to another, switch to a different third party dependency and migrate your data from MySQL to PostgreSQL. Don’t do that at once. It will be hard to review, risky to deploy, likely to conflict with other concurrent changes, hard to undo if something goes wrong. If it affects many backend services, they will be deployed at different times, which adds even more risk and delays the rollout. The definition of "one thing" here is subjective, but, if you can’t summarize your change in one sentence, that means you are probably changing more than one thing. If you can’t turn off your brain while making the change across the codebase or delegate it to an AI agent, you might be changing more than one thing.

## Strategies for changing one thing at a time

There are many ways to turn a big change into a series of "one thing at a time" changes. Sometimes each change will feel meaningless on its own, but the culmination of changes will have a big impact. In these cases, provide code reviewers with context about where you are going with the changes. You should lay out a step-by-step list of refactors in the description of your change and point out how it works. You don’t have to stop your work and wait for each step to merge independently. With a version control system, you should be able to continue your work on top of your previous work, and "stack" your changes. You’ll want to get them reviewed and merged one at a time, but you should never be stuck, unable to do the next step of the refactor. As stacks of changes get deeper, there’s a higher risk of conflicts and of having to undo future steps because of feedback on earlier steps. I aim for a maximum of 3-4 stacked changes when doing this. If you have tools that make this process easy, you might be able to create deeper stacks. Sometimes you can create a tree of changes instead of a stack. If two changes can be merged independently because they touch different parts of the codebase, consider making change A and B in two concurrent pull requests ready for review and then working on change C on top of both A and B while waiting for them to merge.

### Specific tips

Consider these more specific ideas about how to break up large changes:

- Use the "[adapter](https://refactoring.guru/design-patterns/adapter)" pattern to introduce a new API while old code continues to call the old API. An API could be a method signature, a struct, a JSON format, a URL or anything else. Use this instead of "renaming", which requires both adding and removing something at the same time.
- Incrementally remove uses of code you intend to delete. You can periodically try removing the code without merging the change to have your compiler show you the remaining uses.
    - "Deprecate" the old way. For long running refactors, there are tools for flagging APIs and methods as deprecated. Even if there’s no official way to do it, you can add a comment or rename a method, adding "deprecated" to the name.
    - Automate the removal of old usages. This helps with fixing conflicts if the change takes a long time to make. You might use regex replacement, IDE refactoring tools, command line refactoring tools or, these days, AI agents.
- Isolate data migrations from code migrations. Don’t try to deploy both at the same time and make sure each step is properly forward and backward compatible. Your code should first support both the old and new format before you migrate data to the new format. These types of migrations need to be rolled out in 3 steps.
- Duplicate (or version, if not in a monorepo) the code and delete the old copy after the migration is done. There are ways to duplicate only some of the code rather than all of it when working in a monorepo and to allow the callers to control what "version" they are using. This is called "[branch by abstraction](https://martinfowler.com/bliki/BranchByAbstraction.html)".
- Consider the "[strangler fig](https://martinfowler.com/bliki/StranglerFigApplication.html)" pattern for large scale migrations where you start doing things a new way and then slowly chip away at removing the old way. This helps to limit the growth of the old pattern while you are migrating to a new pattern.

I hope that these tips help with your next large refactor. As you get better at these refactors, your team will be more comfortable with letting you do more of them and you’ll get better at juggling multiple concurrent refactors. They take time to review and merge, but if you follow these tips they shouldn’t take too much time and back-and-forth for you to actually implement. If you have any more ideas for how to refactor more effectively, I’d love to hear them! Email me or tweet (X?) at me.