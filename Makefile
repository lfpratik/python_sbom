.PHONY: clean clean-test clean-pyc clean-build clean-venv docs help
.DEFAULT_GOAL := help

PATH := .venv/bin:$(PATH)
export PATH

define BROWSER_PYSCRIPT
import os, webbrowser, sys

from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-venv clean-build clean-pyc clean-test clean-docs

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

clean-docs: ## remove docs artifacts
	rm -f docs/python_sbom.rst
	rm -f docs/modules.rst

clean-venv: ## remove virtualenv artifacts
	rm -fr .venv

venv: .venv

.venv:
	python3 -m venv .venv
	.venv/bin/pip install -r requirements_dev.txt
	.venv/bin/pip install git+https://github.com/licquia/tools-python.git@unified#egg=spdx-tools
	.venv/bin/python setup.py develop

lint: .venv ## check style with flake8
	flake8 python_sbom tests

test: .venv ## run tests quickly with the default Python
	pytest

test-all: .venv ## run tests on every Python version with tox
	tox

coverage: .venv ## check code coverage quickly with the default Python
	coverage run --source python_sbom -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

docs: .venv ## generate Sphinx HTML documentation, including API docs
	rm -f docs/python_sbom.rst
	rm -f docs/modules.rst
	sphinx-apidoc -o docs/ python_sbom
	$(MAKE) -C docs clean
	$(MAKE) -C docs html
	$(BROWSER) docs/_build/html/index.html

servedocs: docs ## compile the docs watching for changes
	watchmedo shell-command -p '*.rst' -c '$(MAKE) -C docs html' -R -D .

release: dist ## package and upload a release
	twine upload dist/*

dist: clean .venv ## builds source and wheel package
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean .venv ## install the package to the active Python's site-packages
	python setup.py install
