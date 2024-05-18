#!/bin/bash

set -e
THISDIR=$(dirname "$(readlink -f "$0")")

function load-dotenv {
    local dotenv_file="${1:-${THISDIR}/.env}"  # Default to .env if no argument is provided

    if [[ ! -f "$dotenv_file" ]]; then
        echo "File $dotenv_file does not exist."
        return 1
    fi

    # Read the .env file line by line
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        # Skip empty lines and comments
        [[ -z "$key" ]] && continue
        [[ "$key" == \#* ]] && continue

        # Remove any surrounding whitespace from the key and value
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Debug: Print the key-value pairs being processed
        #echo "Exporting: $key=$value"

        # Export the variable
        export "$key=$value"
    done < "$dotenv_file"
}

function clean-build {
    local dirs=("build" "dist" "*.egg-info")
    for dir in "${dirs[@]}"; do
        echo "Cleaning $dir..."
        rm -rf $dir
    done
    echo "Cleanup complete."
}

function install {
    python -m pip install --upgrade pip
    python -m pip install --editable "${THISDIR}/[dev]"
}
function lint {
    pre-commit run --all-files
}
function build {
    python -m build --sdist --wheel "${THISDIR}"
}

function start {
    echo "start task not implemented $THISDIR"
}

function default {
    start
}
function publish:test {
    load-dotenv
    twine upload dist/* \
    --repository testpypi \
    --username=__token__ \
    --password="${TEST_PYPI_TOKEN}"
}
function release:test {
    clean-build
    lint
    build
    publish:test
}
function publish:prod {
    load-dotenv
    twine upload dist/* \
    --repository pypi \
    --username=__token__ \
    --password="${PROD_PYPI_TOKEN}"
}
function release:prod {
    clean-build
    lint
    build
    publish:prod
}
function help {
    echo "$0 <task> <args>"
    echo "Tasks:"
    compgen -A function | cat -n
}

TIMEFORMAT="Task completed in %3lR"
time ${@:-default}
