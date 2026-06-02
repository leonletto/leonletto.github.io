---
layout: default
title: When 'Sparse Attention' Actually Works - A Long-Context Followup
---
# When "Sparse Attention" Actually Works

A follow-up to [Why Your Long-Context AI Keeps Forgetting](Why-Your-Long-Context-AI-Keeps-Forgetting.html) — what changes when the architecture stops fighting you.

## The Setup

The previous post pinned the problem on a single setting in Qwen3-Coder's config: `max_window_layers = 28` out of 48. In plain terms, the top 20 layers of that model could only look at a *recent window* of the text instead of the whole thing. And the top layers are where a model ties everything together — connecting the customer's first email to the last one, the symptom to the fix. Narrow their view and the model can't make that connection, no matter how big the context window on the spec sheet is.

Since then I deployed a model whose own model card calls it "sparse attention" — Qwen3.5-35B-A3B — on the same ticket-processing workflow my old model already handled well (Qwen3-30B-A3B-Instruct-2507, a conventional full-attention model). Citation accuracy went up. Noticeably.

On the surface, that looks like a counter-example to the first post. It isn't. The architecture actually *confirms* the point — just by a route I didn't see coming. And the nuance is worth getting right, because "sparse attention" is too blunt a label to tell you anything useful on its own.

## What Qwen3.5-35B-A3B Actually Does

Despite the label, this model isn't "sparse" in the usual sense — it doesn't skip tokens or take clever shortcuts through the text.<sup>[1](#note-1)</sup> It's a *hybrid*. It mixes two kinds of attention layer, in a pattern that repeats every four layers all the way up the stack:

```
Hidden Layout: 10 × (3 × (linear-attention layer) → 1 × (full-attention layer))
```

Read that as: in every block of four layers, three are the cheap kind and one is the expensive kind — and that block repeats ten times, for 40 layers total.

- **30 layers** use **linear attention** (the variant here is called *Gated DeltaNet*). Instead of comparing every token against every other token, each of these layers keeps a running summary that it updates as it reads — a fixed-size memory that doesn't grow no matter how long the text gets.<sup>[2](#note-2)</sup>
- **10 layers** use **ordinary full attention** — the every-token-can-see-every-token kind, the expensive one that can reach anywhere in the text.<sup>[3](#note-3)</sup>

Here's the part that matters: those full-attention layers are sprinkled in at *every level*, including near the top of the stack where the high-level reasoning happens. That's the exact opposite of Qwen3-Coder, which starved its top layers. This model keeps full, look-anywhere attention precisely where the last post argued it matters most.

## Why This Enhances Rather Than Degrades Long Context

The failure I described last time was blunt: the top layers literally couldn't see far-away text. This design avoids that, and adds two more wins on top:

1. **Full attention survives at every level.** The top layers can still reach back and pull a fact from anywhere in the text. The thing the last post warned about simply doesn't happen here.
2. **The cheap layers fail more gracefully.** Regular attention has a well-known weak spot, often called "lost in the middle": when a layer has to split its focus across thousands of tokens at once, each token gets such a thin slice that whatever's in the middle tends to get drowned out. The linear-attention layers don't work that way, so they don't have that particular failure. They have their own limit — their running summary can only hold so much — but in practice it keeps the gist of a long thread surprisingly well.<sup>[4](#note-4)</sup>
3. **The two kinds cover for each other.** The linear layers cheaply carry the running story forward; the full-attention layers jump back to a specific fact when one is needed. For answering a long support thread with quotes you can actually trust, that's exactly the division of labor you want.

## The Memory Dividend: Affording the Full 256K Window

There's a second payoff I didn't appreciate until I had it running: this design is far cheaper to run at long context. That's not just a speed nicety — it's what lets the GPU reach context lengths the old model simply couldn't.

Here's what gets expensive as the text grows, and it isn't the model's weights — those take up a fixed amount of memory you pay for once. It's the **KV cache**. For every token it has already read, each full-attention layer has to keep a little note about that token so it can be looked at again later. That store grows in step with the length of the text. Push toward 256K tokens and it's the KV cache, not the weights, that decides whether the model still fits in GPU memory.

This is where the hybrid layout pays off. In the old model, all 48 layers use full attention, so all 48 keep that growing per-token store. In the new one, only 10 of its 40 layers do. The other 30 are linear-attention layers, whose running summary stays the same size no matter how long the text gets. And the 10 full-attention layers it does keep are more frugal about it — they store roughly half as much per token as the old model did.<sup>[5](#note-5)</sup>

Back-of-envelope, at 16-bit precision:

| Model | Per-token KV cache | KV cache at 256K |
|---|---:|---:|
| Qwen3-30B-A3B-2507 (48 full-attention layers) | ~96 KB | ~26 GB |
| Qwen3.5-35B-A3B (10 full-attention layers) | ~20 KB | ~5 GB |

(The linear-attention layers add a small fixed amount that doesn't grow with length, so it drops out of the comparison.)

That's roughly a **5× cut** in the memory that grows with context — about 21 GB freed up at the full window. And here's where it gets concrete. I run the 16-bit weights on a single 80 GB A100, so the budget is fixed and the math is unforgiving:

| | Weights (16-bit) | KV cache @ 256K | Total |
|---|---:|---:|---:|
| Qwen3-30B-A3B-2507, full window | ~61 GB | ~26 GB | **~87 GB** — over the card |
| Qwen3.5-35B-A3B, full window | ~70 GB | ~5 GB | **~75 GB** — fits |

Look at what that table is saying. The new model is the *bigger* one — about 70 GB of weights against the old model's 61 GB — and it's still the one that fits the full 256K window, because the ~21 GB it saves on KV cache more than covers the ~9 GB of extra weight.

This isn't hypothetical. The old model never reached 256K on this card. Its 61 GB of weights left about 19 GB for the KV cache, and at ~96 KB per token that runs out around **180K tokens** — which is exactly where I capped the context after testing, to stay clear of running out of memory. That real-world ceiling also lines up with the rough math above: 19 GB ÷ 96 KB per token ≈ 190K tokens before overhead, right about the 180K I actually hit. A model with full attention in every layer runs out of card before it reaches the window on its own spec sheet. The hybrid layout is what buys back that last 76K.

The last post's punchline was *the advertised context window isn't the context you actually get*, because the architecture couldn't reason across it. This is the flip side of the same coin: even when a model *can* reason across a long window, you still have to be able to load it — and the same design choice that keeps the reasoning reach also slashes the memory bill for using it.

## Benchmark and Production Signal

Artificial Analysis runs a benchmark called [AA-LCR](https://artificialanalysis.ai/evaluations/artificial-analysis-long-context-reasoning) — Long-Context Reasoning. It measures how well a model finds and reasons over facts buried in a long input. Here's how the two models score, with and without "thinking" (step-by-step reasoning) turned on:

| Model | Without thinking | With thinking |
|---|---:|---:|
| Qwen3-30B-A3B-2507 (what I was running) | **22.7%** | 59.0% |
| Qwen3.5-35B-A3B (new hybrid) | **55.3%** | 62.7% |

The without-thinking numbers look damning. The reality in production wasn't. I'd put Qwen3-30B-A3B-2507 up against several other models on my own ticket workflow, with thinking turned off, and it kept winning. So a 22.7% score doesn't mean the model couldn't do the job. It means it couldn't do the job *on its own*. What I actually ran was the model plus a carefully written prompt — re-read the source, back every claim with a specific passage, check the quotes before answering. That prompt was quietly doing structural work: making up, on the input side, for a weakness on the model side.

That's how to read the jump from 22.7% to 55.3%. It isn't "the old model was broken and this one isn't." It's "the old model needed hand-holding to behave; the new one needs less of it." A better architecture raises the floor — which means less fragile prompt scaffolding to maintain, more room for the hard cases, and a higher ceiling overall.

In my deployment that shows up as the citation-accuracy gain. The same prompt that worked before — go back, look at the source, verify the quote — now produces fewer made-up citations and surfaces more real ones. The prompt is doing the same job; the model is just carrying more of it. That's the tell-tale sign of a genuine long-context improvement in the architecture: the model's basic writing quality barely changes, but the skill of looking things up in a long document — the thing the prompt was compensating for — becomes something the model can do on its own.

## Refined Principle

The lesson isn't "all sparse attention degrades long context." It's narrower and more useful:

> Long-context reasoning lives or dies on whether the *top* layers can still look anywhere in the text. Restrict them — a recent-only window in the top layers, like Qwen3-Coder — and the model can't tie the context together. Spread the cheap attention through *all* the layers instead, keeping some full-attention layers at every level — like Qwen3.5-35B-A3B — and the model keeps its long-context reasoning. Better still, it can afford that reasoning at lengths a full-attention-everywhere model could never fit in memory.

A good prompt can paper over weak top-layer attention — re-read, verify, cite the passage; it all helps. But there's a ceiling on what prompting can rescue, and that ceiling is set by what the architecture can reach on its own. Pick a model that doesn't need rescuing, and those same prompts are freed up to do harder things.

## The Bottom Line

The last post still stands: the advertised context window isn't the context you actually get, and `max_window_layers` is a config setting worth checking. But "sparse attention" as a label is too blunt to be useful. The real question is *where* in the model the cheap attention sits — not whether it's there at all.

If the cheap attention is in the top layers, you have a problem. If it's spread through the model with full attention kept at every level, you have something that can handle long-context work at lengths a full-attention-everywhere model simply can't afford.

## Under the Hood (for the curious)

The body keeps the jargon light on purpose. If you want the precise version, here it is.

1. <a name="note-1"></a>**"Not sparse in the usual sense."** Most things marketed as *sparse attention* — sliding-window attention, Native Sparse Attention, block-sparse routing — save work by letting each token attend to only *some* of the others. This model doesn't prune connections like that. It swaps in a different, cheaper *kind* of attention (linear attention) for most of its layers and keeps full attention for the rest.

2. <a name="note-2"></a>**Linear attention / Gated DeltaNet.** "Linear" refers to cost: the work grows in a straight line with the length of the text — written O(N) — instead of with the *square* of the length — O(N²) — the way full attention does. It manages this by keeping a single fixed-size running state and updating it token by token, rather than storing something for every token. The specific variant here, *Gated DeltaNet*, is in the same family as RetNet and Mamba ([Gated Delta Networks](https://arxiv.org/abs/2412.06464), [DeltaNet](https://arxiv.org/abs/2406.06484)).

3. <a name="note-3"></a>**The full-attention layers.** These 10 layers use grouped-query attention (GQA): 16 query heads but only 2 key/value heads, with 256-dimensional heads (64 of those dimensions carry the rotary position signal, RoPE). Fewer key/value heads is the lever that shrinks per-token memory — see note 5 ([GQA paper](https://arxiv.org/abs/2305.13245)).

4. <a name="note-4"></a>**Why full attention loses the middle.** A full-attention layer scores every token against every other, then runs those scores through a *softmax* — a step that forces the weights to add up to 1 across the whole context. The more tokens there are, the thinner each one's slice, so a fact stranded in the middle can end up with almost no weight. Linear-attention layers blend information through their running state instead, so they don't have this exact failure; their limit is simply how much that fixed-size state can hold.

5. <a name="note-5"></a>**The KV-cache math.** Per token, the cache is roughly `2 (key + value) × layers × KV-heads × head-dim × bytes`. Old model: `2 × 48 × 4 × 128 × 2 ≈ 96 KB/token`. New model: `2 × 10 × 2 × 256 × 2 ≈ 20 KB/token` — fewer full-attention layers (10 vs 48) and fewer key/value heads (2 vs 4) outweigh the larger head dimension. At 256K tokens that's about 26 GB versus 5 GB.

## Further Reading

### On Hybrid and Linear Attention
- **[Qwen3.5-35B-A3B Model Card](https://huggingface.co/Qwen/Qwen3.5-35B-A3B)** - Official architecture description for the hybrid linear/full attention model used in this post
- **[Gated Delta Networks: Improving Mamba2 with Delta Rule](https://arxiv.org/abs/2412.06464)** - The linear-attention layer (Gated DeltaNet) this model uses for 30 of its 40 layers (Yang, Kautz, Hatamizadeh; NVIDIA, ICLR 2025)
- **[Parallelizing Linear Transformers with the Delta Rule over Sequence Length](https://arxiv.org/abs/2406.06484)** - The underlying DeltaNet, and why combining it with ordinary attention works well
- **[GQA: Training Generalized Multi-Query Transformer Models](https://arxiv.org/abs/2305.13245)** - Grouped-query attention, the trick that shrinks the per-token KV cache
- **[Artificial Analysis Long-Context Reasoning Benchmark](https://artificialanalysis.ai/evaluations/artificial-analysis-long-context-reasoning)** - Independent benchmarking with the thinking / non-thinking split visible

### On Attention Mechanisms (carried over from the prior post)
- **[SWAN-GPT: Efficient Long-Context Language Modeling](https://arxiv.org/abs/2504.08719)** - NVIDIA research on interleaving full and sliding window attention layers, with mechanistic analysis of why different layer types learn different representations
- **[Efficient Transformers: A Survey](https://arxiv.org/abs/2009.06732)** - Comprehensive overview of attention mechanism optimizations
- **[Attention Is All You Need](https://arxiv.org/abs/1706.03762)** - The original transformer paper

### Prior Post in This Thread
- **[Why Your Long-Context AI Keeps Forgetting](Why-Your-Long-Context-AI-Keeps-Forgetting.html)** - The original post this one builds on

---

**About This Post**: This is a follow-up to my November 2025 post on long-context failures in code-specialized Qwen models. It documents what I found after deploying a "sparse attention" model that, at first glance, should have contradicted my earlier argument — and what the architectural details actually reveal once you look at where the cheaper attention sits. Based on production deployment processing support tickets at long context.

**Have similar experiences or insights?** I'd love to hear from you. Connect on [LinkedIn](https://www.linkedin.com/in/leonletto/) or [GitHub](https://github.com/leonletto).

---

*Last updated: June 2026*
