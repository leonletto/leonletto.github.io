---
layout: default
title: Beads Gave My Agents Memory. Thrum Gave Them a Voice.
---
# Beads Gave My Agents Memory. Thrum Gave Them a Voice.

I had three AI coding agents working on the same project two months ago. Different terminal windows, different parts of the codebase, each one cranking through tasks autonomously. It felt like the future — until Agent B started rebuilding the authentication module that Agent A had finished twenty minutes earlier.

Nobody told Agent B. Nobody *could* tell Agent B. These agents don't share memory. They don't share context. They can't even see that the other ones exist.

So I did what any reasonable person would do. I became a human message relay. Copy from terminal A, paste into terminal B. "Hey, auth is done, move on to the database layer." Over and over. For three agents, that's three communication pairs. I was spending almost as much time relaying messages as the agents were spending writing code.

But before I tell you what I built next, I need to tell you about the thing that made multi-agent work possible in the first place.

## The First Breakthrough: Giving Agents a Memory

In early December, I watched a podcast where Steve Yegge was talking about [Beads](https://github.com/steveyegge/beads) — a Git-backed issue tracker he'd built as a memory system for AI agents. Something clicked immediately.

Before Beads, I was drowning in markdown files. Every agent session generated its own notes, its own task lists, its own scratchpad of what it was working on. When a session ended or the context window got too long and the AI compressed away the early messages, all of that was gone. I'd start a new session and spend the first five minutes figuring out which of the markdown files to give it so it knew where it left off, what the project was, what had been done, and what was left. Multiply that by three or four agents and you're burning hours on context recovery alone.

Beads replaced all of that with a shared task list that lived in Git. Create an issue, break it into subtasks, set dependencies, assign owners. When an agent's session crashed or its context compacted, it could run one command — `bd ready` — and immediately see what to work on next. No re-explaining. No lost progress. Just pick up the next unblocked task and keep going.

I went from managing one agent at a time to running three or four in parallel, and my productivity jumped 5x-10x. It just *made sense* — agents need a persistent to-do list the same way human teams do.

## The Gap That Beads Couldn't Close

But Beads solved the "what should I work on?" problem, not the "what is everyone else doing right now?" problem.

Agents could see the task list, but they couldn't see each other. Agent B would spot an interesting task in Beads and think "I should grab that one" — not realizing Agent A was already halfway through it but hadn't marked it in-progress yet. Two agents would edit the same file without knowing it, creating merge conflicts that took longer to untangle than the original work. An agent would finish a critical piece of shared infrastructure and nobody else would find out until they hit errors trying to use the old version.

Beads gave my agents memory. What they still didn't have was a voice.

I was still the human relay. Still copying messages between terminals. Still the bottleneck in a system that was supposed to be making me faster.

That's the moment I started building Thrum.

Thrum is a Git-backed messaging system that lets agents coordinate across sessions and machines without relying on an external service.

## What If They Could Just... Talk to Each Other?

That was the missing piece. Not a complex orchestration framework. Not a centralized task queue. Just messages. Persistent messages that survive session boundaries, that work across different machines, and that don't depend on some external cloud service.

I'd already seen what Git-backed persistence did for task tracking with Beads. The same insight applied to messaging: I already had the perfect delivery mechanism in **Git**.

Every developer project already has a Git repository. Git handles authentication, syncing across machines, conflict resolution, and history tracking. It's infrastructure that already exists, already works, and doesn't cost anything extra.

So Thrum stores messages in your Git repo. A background service syncs them automatically. Agents register with a name and role, send messages, check their inbox and listen for new messages. All through a simple CLI or through native AI tool integration.

```bash
thrum init                          # Set up in your repo
thrum daemon start                  # Start the background service
thrum quickstart --role implementer --module auth --intent "Building auth"
thrum send "Auth module complete, ready for review" --mention @reviewer
```

That's it. No accounts. No API keys. No external services. If you can clone a repo, you can use Thrum.

## What It Actually Looks Like In Practice

Here's a real scenario from last week. I had a planning agent and two implementation agents working on the Thrum documentation website (yes, the agents were using Thrum to coordinate building the Thrum docs — more on that in a minute).

The planner broke the work into thirteen tasks with dependencies. Task 7 couldn't start until tasks 3 and 5 were done. Task 13 (build and deploy) was blocked by everything else.

Implementation Agent A picked up the first wave — updating existing docs with new features. Implementation Agent B worked on three brand-new documentation pages in parallel. They messaged their progress through Thrum:

```text
From: @implementer_a
"CLI reference updated with --local flag. Daemon docs cleaned up.
Moving to sync docs."

From: @implementer_b
"Agent configurations page complete. Starting on workflow templates."
```

When Agent A finished a doc that Agent B's page linked to, Agent B knew immediately. No human relay. No duplicated work. When Agent B hit a question about the architecture, it checked what Agent A had already documented rather than re-reading the source code.

Thirteen tasks, two agents working in parallel, two hours. The whole documentation site — landing page, doc viewer, full-text search, twenty-two pages of content — built and deployed.

## The Part Where It Gets Meta

Here's the thing I didn't fully appreciate until I watched it happen: **the agents building the documentation website were coordinated through the very system they were documenting.**

The planner agent sent task assignments through Thrum. The implementation agents reported completions through Thrum. When one agent updated the CLI docs, it messaged the other to rebuild the search index. The background sync kept everyone current.

And because Thrum stores everything in Git, I could go back afterward and see the entire coordination history. Every message, every status update, every handoff. It's like having meeting notes that write themselves, except nobody had to sit through a meeting.

This isn't a contrived demo. This is how the project actually runs, every day. Multiple agents across multiple workspaces, coordinating through persistent messaging, with a human (me) stepping in only for high-level decisions and approvals.

## "But Isn't This Just Slack for Robots?"

Sort of. But the differences matter.

**It lives in your repo.** No separate service to manage, no data leaving your environment. Messages are part of your project, versioned alongside your code. For teams working on sensitive projects, that's a big deal.

**It works offline.** Everything functions locally. Network is only needed to sync across machines — and even that's optional. You can run Thrum in local-only mode for projects where you don't want agent chatter leaving your laptop.

**Security note:** If you want the details on local-only mode and how to keep messages from ever leaving your environment, start with the docs: https://leonletto.github.io/thrum and the security notes here: https://leonletto.github.io/thrum/docs.html#security-cicd.html

**It survives everything.** Session crashes, context window limits, machine reboots. Messages persist because they're committed to version control. An agent can pick up exactly where another left off, even days later.

**It tracks work context, not just messages.** Thrum knows which Git branch each agent is on, what files they've changed, and what commits they haven't merged. Before editing a shared file, an agent can check: "Is anyone else working on this right now?" That alone has saved me hours of merge conflict headaches.

**It pairs with Beads for complete coordination.** Beads handles what agents should work on. Thrum handles what agents are saying to each other. Together, an agent that lost its context can run two commands and know exactly what it was doing *and* what its teammates said while it was offline. That combination — persistent tasks plus persistent messaging — is what took me from "multi-agent is theoretically possible" to "multi-agent is how I work every day."

## Who This Is Actually For

If you're running a single AI agent on simple tasks, you probably don't need this. The overhead isn't worth it for "fix this bug" or "add a button."

But if any of these describe your situation, Thrum might click:

- You're running **multiple AI agents** on the same project and tired of being the relay
- You're doing **multi-session work** where agents need to resume where they left off
- You care about **keeping agent communications private** and in your own infrastructure
- You want to see **what your agents are actually doing** across different workspaces
- You're exploring **autonomous agent workflows** and hitting coordination walls

The sweet spot right now is technical teams experimenting with multi-agent development workflows — using tools like Claude Code, where agents operate in terminal sessions and can run CLI commands natively.

## Getting Started

Thrum is open source and runs on macOS and Linux. The core is a single Go binary with no external dependencies.

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/leonletto/thrum/main/install.sh | bash

# Initialize in your project
cd your-project
thrum init
thrum daemon start

# Register and start sending messages
thrum quickstart --role developer --module backend --intent "Working on API"
thrum send "Hello from the future of agent coordination"
```

There's also an MCP server (`thrum mcp serve`) that plugs directly into Claude Code, so your agents can send and receive messages as native tool calls without shelling out to the CLI.

The [documentation site](https://leonletto.github.io/thrum/) has the full reference — and yes, it was built by the agents, coordinated through Thrum.

## Where This Is Going

Beads made me 5x-10x more productive by giving agents persistent memory across sessions. Thrum added another 2x on top by letting them coordinate in real time — asking questions, announcing completions, avoiding conflicts. The effect is real: agents that can both remember *and* communicate are qualitatively different from agents that can only do one or the other.

Thrum is early. The core messaging and coordination works well — I use it daily across five active development branches with multiple agents. But there's more to build: better visualization of agent activity, richer notification patterns, and smoother onboarding for teams new to multi-agent workflows. One feature I'm adding is a relay agent to allow remote agents to talk in real time as well.

What I'm most interested in is how other teams use it. The multi-agent coordination problem isn't unique to my project. Anyone pushing the boundaries of AI-assisted development is hitting the same walls I hit: agents that can't talk, can't remember, and can't see each other.

If that sounds familiar, [give it a try](https://github.com/leonletto/thrum). And if your agents start having better conversations than your last standup meeting, I want to hear about it.

---

*Thrum is open source under the MIT license. Star it on [GitHub](https://github.com/leonletto/thrum), check the [docs](https://leonletto.github.io/thrum/), or just `thrum init` and see what happens.*
