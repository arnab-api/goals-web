# Human annotation of GoalScope read-outs

`site/annotate.html` (served at `demo/annotate.html` after `make demo`) asks people to grade GoalScope read-outs with
the same four verdicts the LM judges use, then shows how their verdicts compare with Claude Sonnet 4.6 (the paper's
judge) and GPT-5.

- **Items**: the read-outs at the `indent`, `var` and `eq` pivots of the paper's main faithfulness run (Coder-32B, the
  122 goal heads, additive_norm α 0.1), 253 specs × 3 pivots = 759 items, in `site/demos/data/annotation/items.json`
  (written by the goals repo: `python scripts/evaluation/annotation_write_site_data.py`). The task and code shown for
  each item come from the Eval tab's data (`site/demos/data/faithfulness/<spec>.json`).
- **Sampling**: the user picks 5 / 10 / 15 / 20 (`sizes` in `site/annotate-config.js`). The page samples that many
  *specs* uniformly among the ones this browser has not labeled yet, and one random pivot per spec, so nobody sees the
  same frontier twice, within or across sessions (browser storage; with a server, also the specs the server has for
  this browser's id, e.g. after the browser storage was cleared of everything but the id).
- **Anonymous**: no name or other personal information is asked for or stored. Each browser gets a random pseudonym
  ("plucky puffin") and a random id on its first visit, kept in its local storage. The same person on another browser
  or device is a new annotator.
- **Flow**: one read-out at a time; a verdict (keys 1–4), then an optional comment (Enter = submit, Esc = skip).
  Unfinished sessions can be resumed from the start screen. At the end: the user's verdict counts, the agreement with
  each LM (same verdict, and YES vs. not-YES), and a per-item table.
- **Stored per answer**: session id, pseudonym, random browser id, item (spec, pivot, frontier, read-out), verdict,
  comment, time to verdict and total time, both LM verdicts, timestamp. Nothing else (no user agent; Apps Script does
  not pass the caller's IP to the script). Per finished session: the summary and agreement
  plus the full JSON.

## Storage: a Google Sheet (Apps Script web app)

1. Create a Google Sheet (e.g. "GoalScope annotations").
2. **Extensions → Apps Script**. Replace the contents of `Code.gs` with `annotation/apps_script.gs`. Save.
3. Optional: set `SECRET` at the top to a random string (it keeps casual POSTs out; it is visible in the page source,
   so it is not real authentication).
4. **Deploy → New deployment → Select type: Web app**. *Execute as*: Me. *Who has access*: Anyone. Deploy, authorize.
5. Copy the web-app URL (`https://script.google.com/macros/s/…/exec`) into `site/annotate-config.js`:
   ```js
   window.GS_ANNOTATION = { endpoint: "https://script.google.com/macros/s/…/exec", secret: "<SECRET or empty>", sizes: [5, 10, 15, 20] };
   ```
6. `make demo`, commit, push. Check: open the URL in a browser; it answers `{"ok":true,"service":"goalscope-annotation"}`.

The sheet gets two tabs on first use: `responses` (one row per answer) and `sessions` (one row per finished session).
After editing the script, redeploy with **Manage deployments → edit → Version: New version** (the URL stays the same).

Without an endpoint the page still works: answers stay in the browser (`localStorage`) and the summary offers a JSON
download. Answers that fail to reach the server are queued in the browser and retried on the next answer or visit.

## Notes

- The LM verdicts are in `items.json`, so they are visible to anyone who opens the network tab; the page only shows
  them after a session.
- The judges' HEAVY_LOOP (a short repeating cycle) is shown as MALFORMED, matching this page's definition.
- About 94% (Claude) / 97% (GPT-5) of these items are judged YES, so a uniform sample is mostly YES and the agreement
  on the rarer verdicts rests on few items.
