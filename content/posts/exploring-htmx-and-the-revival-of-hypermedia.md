---
title: "Exploring HTMX and the Revival of Hypermedia"
date: 2023-10-14T00:00:00Z
---

I recently taught myself HTMX, and I'm excited to see its growth because it revives an old idea that the world has forgotten: hypermedia.. Hypermedia was behind the original growth of the internet and, through HTMX it might be able to bring a new level of efficiency and productivity to a world tired of JavaScript single page applications and 10MB web pages. It’s promoted as a way to make back-end developers more productive by learning a little bit of front-end. I have some concerns about it that I hope to be addressed over time, but let’s start by looking at what it is.

[HTMX](https://htmx.org/) emerged around 2020, and in 2022, [a book](https://hypermedia.systems/) was published that delves into the history and philosophy of HTMX. It also includes a comprehensive tutorial on progressively enhancing a web 1.0 application using HTMX. I highly recommend this book to anyone interested in learning more about HTMX.

For web developers, the main concept is that HTML serves as both the application state and API. In a pure HTMX application, temporary state should not be stored in JavaScript or local storage. Instead, data is received from the server as HTML snippets, and all behavior is defined in HTML. To achieve this, HTMX augments HTML with simple yet powerful additional attributes that are capable of building most web UIs.

## The many ways to use HTMX

After reading the book, I realized that there are many ways to use HTMX, not just the ones that the authors promote. The most obvious one is the one described in the book: take a web 1.0 website and organize and render templates in various slightly more advanced ways to create a more interactive application. Going down that path, there is a choice to be made about how to write the HTML templating logic. I see two possible ways: either interface with the business logic of the application directly or write an HTMX rendering layer that turns a data API into a UI. The former provides productivity benefits that are unique to the hypermedia architecture and is promoted by the book. The latter allows for more gradual adoption in an environment where the data APIs already exist. This also enforces a clear separation between display logic and business logic and promotes dogfooding of the data API. In a microservices environment, a third, more advanced strategy may be worth considering. HTMX can be leveraged to assemble various HTML fragments from different sources, potentially allowing each microservice to provide its own HTML fragments that are only assembled once they reach the browser. This level of modularity is challenging to achieve in single page applications, but is readily available with HTMX out of the box.

### HTMX SPAs

Another use that is not mentioned in the book is what I refer to as HTMX SPAs (single page applications). To my knowledge, this strategy has not been implemented yet and it may be worth exploring in a separate blog post. Let's briefly walk through it.

First, imagine a service that communicates with a data API and renders an HTMX application. This service can be "deployed" to the browser just as easily as to a back-end server. There are two obvious ways to deploy it: JavaScript (either natively written or transpiled) or web assembly. In either case, a JavaScript library needs to integrate with the HTMX library, or HTMX itself needs to be modified so that all requests to the "server" are directed to the locally deployed "HTMX SPA".

This approach may be considered controversial by both the HTMX community and the JavaScript community, so it is unlikely to gain widespread adoption. However, [at least one person](https://github.com/richardanaya/wasm-service) has attempted it and used service workers, which is an interesting idea. In their demo, requests never reach a server and are served in under 5ms.

I am not yet aware of the benefits and limitations of HTMX SPAs, but I can see that it would allow for any programming language to be used for building HTML-based SPAs.

## Flexibility: good and bad

{{< figure src="/images/exploring-htmx-1.png" title="Discord channel list" height="450px" >}}

Clearly, HTMX is a very flexible technology. It is not very opinionated, except in its belief that the browser should act as a hypermedia client and the API should be a hypermedia one (generally HTML). This approach allows for a wide range of possibilities to be explored, and I am excited to see how HTMX develops further. However, this flexibility also means that there are many ways to accomplish the same thing. While there is a list of examples available [on the HTMX website](https://htmx.org/examples/), I personally feel that they are not sufficient. I have yet to learn the best practices, and it is possible that they have not been fully developed yet. It would be helpful to have some guidelines on what to do and what not to do with HTMX. I am concerned that sharing components and best practices might be challenging due to their strong dependence on the server-side language, templating system, and web framework being used. The image that displays the HTMX Discord channel list highlights the level of fragmentation that exists between different back-end languages. The recommendation from the authors appears to be to leverage an existing web 1.0 server-side rendering framework.

## Versioning

I read somewhere claims that “you don’t need versioning with HTMX” but that doesn’t seem true. Versioning is not necessary when rendering a form with a stable ID and and the server updates to a new version that has a slightly different form. However, the hypermedia client will do the “wrong” thing if the back-end is updated to use a different route for the form or changes the ID of the form or even changes the name of a query parameter. It’s not clear to me how to manage versioning and compatibility without unpredictable and risky partially broken pages.

My first idea is to always force page reloads as soon as the client detects that the server has been upgraded, but in a large application this can happen too often and can be disruptive if it causes the client to lose its state (ex. form state). Another strategy is to keep around the old server to serve requests from the old clients and shut down the old server only after a certain amount of time passes. There can be a hybrid approach where after a certain amount of time, a client refresh is forced on next request. I don’t know what the best practices around this are, and again, it would have to be implemented differently for every language and deployment strategy.

## How I plan to use HTMX

I see the potential for HTMX to make back-end engineers more productive and I plan to use HTMX to build internal tools because I want to start experimenting with it and building out best practices around it. Internal tools have very little specific requirements in terms of UI and UX as long as they work and are safe. If I, a primarily back-end engineer, can build UIs with it, I consider that a big win. I like that it’s free, easy to deploy, not too opinionated and there is no extra compilation step. If I tried to build UIs in web 1.0 style without HTMX, I’d encounter a lot of resistance from both users and other engineers, so I think HTMX can help bridge the gap in terms of UX and let me build UIs. I hope that HTMX will continue to develop and the community around it will continue to grow so that I will eventually feel comfortable using it in user facing applications. I hope this comeback of hypermedia lowers the barrier to entry for new engineers who want to build UIs and it can narrow the gap between “front-end” and “back-end” developers, speeding up iteration cycles. Let’s see what the next few years bring!

## Conclusion

I believe in the mission of HTMX and I do think that, in many cases, it can reduce complexity. I don’t feel confident enough to use it in a client facing website yet, but as I learn more about how to use it, my confidence will likely increase. I hope to see more development in server side rendering frameworks and best practices around HTMX.

Read more about HTMX at [https://htmx.org/](https://htmx.org/).
