# Companion website for "Goal Encoding in LLMs" -> https://goals.baulab.info
# Everything that is served lives in public/ (baulab.info static hosting serves public/ as committed).
#
#   make demo    rebuild the GoalScope demo pages in the goals repo and sync its runtime files into public/demo/
#   make images  re-render the front-page images from the paper draft PDFs
#   make serve   preview public/ at http://localhost:8765 (the demo fetch()es JSON, so file:// does not work)

GOALS   ?= ..# the goals research repo (this repo sits inside it, gitignored)
OVERLEAF ?= $(GOALS)/Overleaf-draft/Goals-Overleaf
PYTHON  ?= python
PORT    ?= 8765

.PHONY: all demo images serve check

all: check

demo:
	cd $(GOALS) && $(PYTHON) web/build_site.py
	rsync -a --delete --info=name1 \
	  --exclude='/data/' --exclude='/data_legacy/' --exclude='__pycache__/' --exclude='/web' \
	  --exclude='*.py' --exclude='/subspace_viz.html' \
	  $(GOALS)/web/ public/demo/

images:
	pdftoppm -png -r 40 -f 1 -l 1 -singlefile $(OVERLEAF)/main.pdf public/images/paper-thumb
	pdftoppm -png -r 220 -singlefile $(OVERLEAF)/Figures/figure1.pdf public/images/teaser

serve:
	$(PYTHON) -m http.server $(PORT) --directory public

check:
	@test -f public/index.html || (echo "public/index.html missing" && exit 1)
	@test -f public/demo/index.html || (echo "public/demo/index.html missing (run make demo)" && exit 1)
	@! grep -rlE '(src|href)="/[^/]' public --include='*.html' || (echo "absolute local paths found above" && exit 1)
	@echo "public/ looks deployable"
