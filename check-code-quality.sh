#!/bin/bash

#set -e

EXIT_STATUS=0

black --config ./.black.toml . || ((EXIT_STATUS++))
pylint --rcfile .pylintrc *.py **.py **/*.py || ((EXIT_STATUS++))
flake8 --config .flake8 || ((EXIT_STATUS++))
mypy . --exclude venv  || ((EXIT_STATUS++))
isort . --settings .isort.cfg || ((EXIT_STATUS++))
echo "#################################################"
echo "###############FIXING WITH RUFF##################"
ruff check . --config ruff.toml --fix || ((EXIT_STATUS++))

echo $EXIT_STATUS
