# ANON branch: the anonymous review demo. public/ IS the GoalScope demo (no front page, no slides, no author info);
# served by Cloudflare (wrangler.jsonc -> public/). The named project page lives on branch main.
#
#   make demo    render site/ (the demo's source: pages from site/data via the goals repo's renderer) into public/
#   make serve   preview public/ at http://localhost:8765 (the demo fetch()es JSON, so file:// does not work)

GOALS   ?= ..# the goals research repo (this repo sits inside it, gitignored)
PYTHON  ?= python
PORT    ?= 8765

.PHONY: all demo serve check

all: check

demo:
	GOALS_REPO=$(GOALS) $(PYTHON) site/build_site.py
	rsync -a --delete --info=name1 \
	  --exclude='/data/' --exclude='/data_legacy/' --exclude='__pycache__/' \
	  --exclude='*.py' --exclude='*.sh' --exclude='/robots.txt' \
	  site/ public/

serve:
	$(PYTHON) -m http.server $(PORT) --directory public

check:
	@test -f public/index.html || (echo "public/index.html missing (run make demo)" && exit 1)
	@test -f public/faithfulness.html || (echo "public/faithfulness.html missing (run make demo)" && exit 1)
	@! grep -rlE '(src|href)="/[^/]' public --include='*.html' || (echo "absolute local paths found above" && exit 1)
	@! grep -rlIE 'Sen Sharma|Northeastern|baulab|sensharma|Bau, ' public || (echo "identifying strings found above" && exit 1)
	@echo "public/ looks deployable (anonymous)"
