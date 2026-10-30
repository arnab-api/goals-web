"""Build the GoalScope demo site: render the code-task pages from their data JSON.

    site/data/<model>/<source>/<task>.json    raw GoalScope rows, written by the goals repo
                                              (scripts/run_goalscope_web.py via src.goals.site_data.write_data):
                                              {"task", "model", "source", "meta": {...},
                                               "rows": [{"pos", "token", "patched_gen", "scoped"}, ...]}
    site/pages/<model>/<source>/<task>.html   rendered by the goals repo's src.goals.goalscope_viz
    site/manifest.json, site/labels.json      {model: {source: [task, ...]}} and display labels for index.html

The ICL / EM tabs (icl.html, em.html) read site/demos/data/{icl,em}/ directly; nothing to build for them.

    GOALS_REPO=/path/to/goals python site/build_site.py      (default GOALS_REPO: the parent of this repo)

``make demo`` runs this, then syncs site/ into public/demo/.
"""

import json
import os
import re
import sys
from pathlib import Path

WEB = Path(__file__).resolve().parent
GOALS = Path(os.environ.get("GOALS_REPO", WEB.parent.parent)).resolve()   # the goals research repo
sys.path.insert(0, str(GOALS))
from src.goals.goalscope_viz import goalscope_qualitative_html  # noqa: E402

DATA, PAGES = WEB / "data", WEB / "pages"


BANK = GOALS / "data" / "well-known-tasks"
PINS = WEB / "pins.json"   # {"<model>/<source>/<task>": [pos, ...]} read-outs pinned when a page opens


def task_label(source: str, task: str) -> str:
    """Sidebar / title label. HumanEval / MBPP ids become ``<number>_<function name>`` (e.g. ``125_find_length``);
    ds_and_algo tasks keep their name. ``source`` may carry a suffix (``mbpp-v2-smoke``) — the bank dir is its prefix."""
    base = source.split("-", 1)[0]
    m = re.fullmatch(rf"{base}_(\d+)", task)
    if m and (BANK / base / f"{task}.json").exists():
        return f"{m.group(1)}_{json.loads((BANK / base / f'{task}.json').read_text())['function_name']}"
    return task


def build() -> dict:
    manifest, labels = {}, {}
    pins = json.loads(PINS.read_text()) if PINS.exists() else {}
    for fp in sorted(DATA.glob("*/*/*.json")):
        d = json.loads(fp.read_text(encoding="utf-8"))
        model, source, task = fp.parent.parent.name, fp.parent.name, fp.stem
        out = PAGES / model / source / f"{task}.html"
        out.parent.mkdir(parents=True, exist_ok=True)
        # read-outs on the LEFT (the paper layout: they come before the code they anticipate); the site's nav
        # sidebar sits on the right (index.html)
        label = labels.setdefault(f"{source}/{task}", task_label(source, task))
        want = pins.get(f"{model}/{source}/{task}", [])
        scoped = {r["pos"] for r in d["rows"] if r["scoped"] and (r.get("patched_gen") or "").strip()}
        if set(want) - scoped:     # positions go stale if the task's data is regenerated
            print(f"  WARNING {model}/{source}/{task}: pins {sorted(set(want) - scoped)} are not scoped tokens")
        goalscope_qualitative_html(d["rows"], title=f"{label.replace('_', ' ')}  ·  {model}", save_path=str(out),
                                   initial_pins=want)
        manifest.setdefault(model, {}).setdefault(source, []).append(task)
    for model, srcs in manifest.items():          # numbered tasks (HumanEval / MBPP) in numeric order
        for source, tasks in srcs.items():
            lab = lambda t: labels[f"{source}/{t}"]
            tasks.sort(key=lambda t: (0, int(lab(t).split("_", 1)[0]), "") if lab(t).split("_", 1)[0].isdigit()
                       else (1, 0, lab(t)))
    (WEB / "manifest.json").write_text(json.dumps(manifest, indent=2))
    (WEB / "labels.json").write_text(json.dumps(labels, indent=1))      # {"<source>/<task>": display label}
    return manifest


def main():
    m = build()
    for model, srcs in m.items():
        for src, tasks in srcs.items():
            print(f"  {model}/{src}: {len(tasks)} pages")
    print(f"manifest -> {WEB / 'manifest.json'}")


if __name__ == "__main__":
    main()
