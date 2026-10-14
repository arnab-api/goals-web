# goals-web

Companion website for *Goal Encoding in LLMs*, served at https://goals.baulab.info.

Static hosting on baulab.info serves the `public/` directory of this repo as committed (a GitHub push webhook
triggers the update; see the onramp wiki page "Websites at domain.baulab.info").

- `public/index.html` — front page (placeholder, in the style of filter.baulab.info)
- `public/demo/` — the GoalScope demo (task browser, ICL and chat/EM pages), copied from the goals repo's `web/`

Rebuild the demo from the goals repo with `make demo`, refresh the paper images with `make images`, and preview
with `make serve` (then open http://localhost:8765).
