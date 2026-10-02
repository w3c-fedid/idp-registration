# This Makefile assumes you have a local install of bikeshed. Like any
# other Python tool, you install it with pip:
#
#     python3 -m pip install bikeshed && bikeshed update

# It also assumes you have doctoc installed. This is a tool that
# automatically generates Table of Contents for Markdown files. It can
# be installed like any other NPM module:
#
#    npm install -g doctoc

.PHONY: all publish clean update-explainer-toc
.SUFFIXES: .bs .html

all: publish update-explainer-toc

clean:
	rm -rf build *~

publish: index.html account-registry.html

update-explainer-toc: README.md Makefile
	doctoc $< --title "## Table of Contents" > /dev/null

# HTML files are committed at the repository root so that GitHub Pages can
# serve them directly.
index.html: work-item.bs Makefile
	bikeshed --die-on=warning spec $< $@

account-registry.html: account-registry.bs Makefile
	bikeshed --die-on=warning spec $< $@
