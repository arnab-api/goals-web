# Companion website for "Goal Encoding in LLMs" -> https://goals.baulab.info
# Everything that is served lives in public/ (baulab.info static hosting serves public/ as committed).
#
#   make demo    rebuild the GoalScope demo pages in the goals repo and sync its runtime files into public/demo/
#   make images  re-render the front-page images from the paper draft PDFs
#   make slides  export the visible (non-hidden) slides of the talk deck to public/slides/ (PDF, backups dropped; linked from the front page)
#   make serve   preview public/ at http://localhost:8765 (the demo fetch()es JSON, so file:// does not work)

GOALS   ?= ..# the goals research repo (this repo sits inside it, gitignored)
OVERLEAF ?= $(GOALS)/Overleaf-draft/Goals-Overleaf
PYTHON  ?= python
PORT    ?= 8765
DECK    ?= $(GOALS)/Presentation/Goals_lab_talk.pptx
PDFMARK := [/Title (Goal Encoding in LLMs: talk slides) /Author (Arnab Sen Sharma, Eric Todd, Sheridan Feucht, Andy Arditi, Rohit Gandikota, Natalie Shapira, Gabriele Sarti, Constanza Fierro, Lisa Schut, David Bau) /Subject (Do LLMs have goals? https://goals.baulab.info/) /DOCINFO pdfmark
SLIDETMP := $(shell mktemp -d -u /tmp/goals-slides.XXXXXX)

.PHONY: all demo images slides serve check

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
	pdftoppm -png -r 200 -singlefile $(OVERLEAF)/Figures/goalscope/goalscope-schema-eval-crop.pdf public/images/goalscope
	pdftoppm -png -r 200 -singlefile $(OVERLEAF)/Figures/appendix/goals-icl-em-main_updated-crop.pdf public/images/beyond-code

# LibreOffice's PDF export skips hidden slides, so the site shows exactly the visible deck.
slides:
	mkdir -p $(SLIDETMP) && cp $(DECK) $(SLIDETMP)/Goals_lab_talk.pptx
	soffice -env:UserInstallation=file://$(SLIDETMP)/lo --headless --convert-to pdf --outdir $(SLIDETMP) $(SLIDETMP)/Goals_lab_talk.pptx
	rm -rf public/slides && mkdir -p public/slides
	@# drop the backup slides: everything from the "Backup" divider page on
	pdf=$(SLIDETMP)/Goals_lab_talk.pdf; n=$$(pdfinfo $$pdf | awk '/^Pages:/{print $$2}'); last=$$n; \
	for i in $$(seq 1 $$n); do pdftotext -f $$i -l $$i $$pdf - | grep -qx 'Backup' && { last=$$((i-1)); break; }; done; \
	echo "keeping slides 1-$$last of $$n"; \
	gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -dFirstPage=1 -dLastPage=$$last -sOutputFile=public/slides/Goals_lab_talk.pdf -c "$(PDFMARK)" -f $$pdf
	pdftoppm -jpeg -jpegopt quality=85 -scale-to-x 240 -scale-to-y -1 -f 1 -l 1 -singlefile $(SLIDETMP)/Goals_lab_talk.pdf public/images/slides-thumb
	rm -rf $(SLIDETMP)

serve:
	$(PYTHON) -m http.server $(PORT) --directory public

check:
	@test -f public/index.html || (echo "public/index.html missing" && exit 1)
	@test -f public/demo/index.html || (echo "public/demo/index.html missing (run make demo)" && exit 1)
	@test -f public/slides/Goals_lab_talk.pdf || (echo "public/slides missing (run make slides)" && exit 1)
	@! grep -rlE '(src|href)="/[^/]' public --include='*.html' || (echo "absolute local paths found above" && exit 1)
	@echo "public/ looks deployable"
