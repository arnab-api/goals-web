/**
 * GoalScope human-annotation backend: a Google Apps Script web app bound to a Google Sheet.
 * The annotation page (site/annotate.html) POSTs every answer and every finished session here, and GETs the specs a
 * browser has already labeled (so nobody is asked about the same frontier twice). Annotators are anonymous: "user"
 * is a random pseudonym ("plucky puffin") and "uid" a random id, both generated in the browser; nothing about the
 * person (name, e-mail, user agent, IP) is collected. Apps Script does not expose the caller's IP to the script.
 *
 * Setup (once):
 *   1. Create a Google Sheet. Extensions -> Apps Script. Replace Code.gs with this file. Save.
 *   2. (optional) Set SECRET below to a random string and put the same string in site/annotate-config.js.
 *   3. Deploy -> New deployment -> type "Web app"; Execute as: Me; Who has access: Anyone. Authorize.
 *   4. Copy the web-app URL (https://script.google.com/macros/s/.../exec) into site/annotate-config.js (endpoint).
 *   After editing this script: Deploy -> Manage deployments -> edit -> Version: New version (the URL stays).
 *
 * Sheets (created on first use):
 *   responses : one row per answered read-out
 *   sessions  : one row per finished session (summary + agreement with the LM judges, and the full JSON)
 */
const SECRET = "";   // optional shared token; must match annotate-config.js

const RESPONSE_COLS = ["received_at", "session_id", "user", "uid", "index", "n", "item_id", "spec", "pivot",
  "frontier_id", "readout", "verdict", "comment", "ms_to_verdict", "ms_total", "claude", "gpt", "answered_at"];
const SESSION_COLS = ["received_at", "session_id", "user", "uid", "n", "started_at", "finished_at",
  "agree_claude", "agree_gpt", "agree_yes_claude", "agree_yes_gpt", "counts", "json"];

function sheet_(name, cols) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sh = ss.getSheetByName(name);
  if (!sh) {
    sh = ss.insertSheet(name);
    sh.appendRow(cols);
    sh.setFrozenRows(1);
  }
  return sh;
}

function json_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  let body;
  try { body = JSON.parse(e.postData.contents); } catch (err) { return json_({ok: false, error: "bad json"}); }
  if (SECRET && body.secret !== SECRET) return json_({ok: false, error: "bad secret"});
  const lock = LockService.getScriptLock();
  lock.waitLock(20000);
  try {
    const now = new Date().toISOString();
    if (body.type === "response") {
      const r = body.response || {};
      sheet_("responses", RESPONSE_COLS).appendRow(RESPONSE_COLS.map(c => c === "received_at" ? now : (r[c] ?? "")));
    } else if (body.type === "session") {
      const s = body.session || {};
      const row = SESSION_COLS.map(c => c === "received_at" ? now : c === "json" ? JSON.stringify(s)
        : c === "counts" ? JSON.stringify(s.counts || {}) : (s[c] ?? ""));
      sheet_("sessions", SESSION_COLS).appendRow(row);
    } else {
      return json_({ok: false, error: "unknown type"});
    }
    return json_({ok: true});
  } finally {
    lock.releaseLock();
  }
}

// GET ?action=seen&uid=<browser id>  ->  {ok, specs: [spec ids this browser has already labeled]}
function doGet(e) {
  const p = (e && e.parameter) || {};
  if (SECRET && p.secret !== SECRET) return json_({ok: false, error: "bad secret"});
  if (p.action !== "seen") return json_({ok: true, service: "goalscope-annotation"});
  const sh = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("responses");
  if (!sh || sh.getLastRow() < 2) return json_({ok: true, specs: []});
  const rows = sh.getRange(2, 1, sh.getLastRow() - 1, RESPONSE_COLS.length).getValues();
  const id = RESPONSE_COLS.indexOf("uid"), is = RESPONSE_COLS.indexOf("spec");
  const specs = {};
  if (p.uid) rows.forEach(r => { if (r[id] === p.uid) specs[r[is]] = 1; });
  return json_({ok: true, specs: Object.keys(specs)});
}
