# goals-web

Companion website for *Goal Encoding in LLMs*, served at https://goals.baulab.info.

Static hosting on baulab.info serves the `public/` directory of this repo as committed (a GitHub push webhook
triggers the update; see the onramp wiki page "Websites at domain.baulab.info").

- `public/index.html` — front page (placeholder, in the style of filter.baulab.info)
- `public/demo/` — the served GoalScope demo (task browser, ICL and chat/EM pages), built from `site/`
- `site/` — the demo's source: HTML/JS/CSS, `pins.json`, the code-task data `site/data/<model>/<source>/<task>.json`,
  the ICL/EM data `site/demos/data/{icl,em}/`, and `build_site.py`, which renders the code-task pages with the goals
  repo's `src.goals.goalscope_viz`. The data is written by the goals repo (`src.goals.site_data`, used by
  `scripts/run_goalscope_web.py`, `scripts/icl/icl_write_site_data.py`, `scripts/em/em_write_site_data.py`).

Rebuild the demo with `make demo` (needs the goals repo: `GOALS=/path/to/goals`, default `..`), refresh the paper images with `make images`, and preview
with `make serve` (then open http://localhost:8765).
