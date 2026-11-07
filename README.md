# GoalScope demo (anonymous)

Interactive demo of GoalScope: natural-language read-outs of an LLM's goal heads while it writes code (Code, Eval),
answers few-shot prompts (ICL) and chats (EM). This branch (`anon`) holds only the demo, without author or project
information, for anonymous review.

- `public/` — the served site (built from `site/`; Cloudflare serves it via `wrangler.jsonc`)
- `site/` — the source: HTML/JS/CSS, the code-task data `site/data/<model>/<source>/<task>.json`, the ICL / EM / Eval
  data `site/demos/data/{icl,em,faithfulness}/`, and `build_site.py`, which renders the code-task pages

Rebuild with `make demo` (needs the research repo's renderer, `GOALS=/path/to/repo`), preview with `make serve`
(http://localhost:8765), and `make check` before deploying.
