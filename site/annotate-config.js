/* Human-annotation page settings (site/annotate.html).
 * endpoint: the Google Apps Script web-app URL (see annotation/apps_script.gs). Empty = no server: answers are kept in
 *           this browser only (localStorage) and can be downloaded as JSON at the end of a session.
 * secret:   optional shared token; must equal SECRET in apps_script.gs. */
window.GS_ANNOTATION = {
  endpoint: "https://script.google.com/macros/s/AKfycbziJWkXIYYupoUFHXmBPu5igFYzrgDj6JGujzQCRTVxaaknyGgdZOGuC_NFlatY-uNv/exec",
  secret: "",
  sizes: [5, 10, 15, 20],
};
