.DEFAULT_GOAL := help

# ============================================================================
# Make task folder in ./scripts folder
# ============================================================================
.PHONY: task
task: ## Make a folder as task with input/ src/ output/ (Usage: make task newtask=newtask)
task: 
	echo "==> $@"
	echo "==> Populating $(newtask) as a folder..."
	mkdir $(newtask) && cd $(newtask) && mkdir input output src
	# Symlink utilities.py from scripts/utilities.py
	cd $(newtask)/src && ln --symbolic --force --verbose ../../utilities.py .
	
# ============================================================================
# Lint utilities.py
# ============================================================================
.phony: type
MYPY_OPTS := --ignore-missing-imports \
	--check-untyped-defs \
	--exclude=.*__init__\.py$
type: ## Check static typing in Python
	@echo "==> $@"
	mypy $(MYPY_OPTS) utilities.py

.phony: pyflakes
pyflakes: ## Lint with pyflakes
	pyflakes utilities.py

.phony: docstring
docstring: ## Check module and function docstrings
	pydocstyle utilities.py

.phony: isort
isort: ## Sort imports
	isort utilities.py

.phony: black
BLACK_OPTS ?= -l 88
black: ## Format style with black
	black $(BLACK_OPTS) utilities.py

.phony: lint
lint: ## Lint py script
lint: pyflakes type docstring isort black 

# ============================================================================
# Set up the Python virtual environment and prepare the Jupyter distribution
# ============================================================================
.PHONY: setup
VENVPATH ?= venv_socialproof
ifeq ($(OS),Windows_NT)
	VENVPATH :=  c:/users/admin/$(VENVPATH)
	ACTIVATE_PATH := $(VENVPATH)/Scripts/activate
else
	ACTIVATE_PATH := $(VENVPATH)/bin/activate
endif
REQUIREMENTS := ./requirements.txt
setup: ## Set up venv	
setup: $(REQUIREMENTS)
	@echo "==> $@"
	@echo "==> Creating and initializing virtual environment..."
	rm -rf $(VENVPATH)
	python -m venv $(VENVPATH)
	. $(ACTIVATE_PATH) && \
		pip install --upgrade pip && \
		which pip && \
		pip list && \
		echo "==> Installing requirements" && \
		pip install -r $< && \
		jupyter contrib nbextensions install --sys-prefix --skip-running-check && \
		python -m ipykernel install --user --name=$(VENVPATH) --display-name "Python ($(VENVPATH))" && \
		echo "==> Packages available:" && \
		which pip && \
		pip list && \
		which jupyter && \
		deactivate
	@echo "==> Setup complete."

# ============================================================================
# Open Jupyter notebook in the venv
# ============================================================================
.PHONY: jn
jn: ## Launch jupyter notebook in venv
	@echo "==> $@"
	if [ -f $(VENVPATH)/Scripts/activate ]; then \
		. $(VENVPATH)/Scripts/activate && jupyter notebook; \
	elif [ -f $(VENVPATH)/bin/activate ]; then \
		. $(VENVPATH)/bin/activate && jupyter notebook; \
	else \
		@echo "No venv found"; \
	fi
	
# ============================================================================
# Other utilities
# ============================================================================
.PHONY: help
help: ## Show this help message and exit
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'
