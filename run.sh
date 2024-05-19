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

function clean {
    local dirs=("build" "dist" "*.egg-info" "*htmlcov" ".coverage")
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
function lint:ci {
    local SKIP_IN_CI="no-commit-to-branch"
    SKIP=${SKIP_IN_CI} pre-commit run --all-files
}

function test:quick {
    PYTEST_EXIT_STATUS=0
    python -m pytest -vv -m 'not slow' "${THISDIR}/tests"   \
            --cov="${THISDIR}/packaging_demo" \
            --cov-report=html \
            --cov-report=term \
            --cov-fail-under=40 || ((PYTEST_EXIT_STATUS+=$?))
            mv htmlcov "${THISDIR}/test-reports/"
    return $PYTEST_EXIT_STATUS
}
function test {
    PYTEST_EXIT_STATUS=0
    if [ $# -eq 0 ]; then
        python -m pytest -vv "${THISDIR}/tests/"    \
         --cov="${THISDIR}/packaging_demo" \
         --cov-report=html \
         --cov-report=term \
         --cov-fail-under=40 || ((PYTEST_EXIT_STATUS+=$?))
        mv htmlcov "${THISDIR}/test-reports/"
    else
        python -m pytest -vv "$@"
    fi
    return $PYTEST_EXIT_STATUS
}
function test:wheel-locally {
    desactivate || true
    rm -rf test-env || true
    python -m venv test-env
    source test-env/bin/activate
    clean
    pip install build
    build

    PYTEST_EXIT_STATUS=0
    pip install ./dist/*.whl pytest pytest-cov
    INSTALLED_PKG_DIR="$(python -c 'import packaging_demo; print(packaging_demo.__path__[0])')"
    echo "Installed package dir: $INSTALLED_PKG_DIR"
    if [ $# -eq 0 ]; then
        python -m pytest -vv "${THISDIR}/tests/"    \
         --cov="${INSTALLED_PKG_DIR}" \
         --cov-report=html \
         --cov-report=term \
         --cov-fail-under=40 || ((PYTEST_EXIT_STATUS+=$?))
        mv htmlcov "${THISDIR}/test-reports/"
    else
        python -m pytest -vv "$@"
    fi
    desactivate
    return $PYTEST_EXIT_STATUS
}

function test:ci {

    PYTEST_EXIT_STATUS=0
    INSTALLED_PKG_DIR="$(python -c 'import packaging_demo; print(packaging_demo.__path__[0])')"
    echo "Installed package dir: $INSTALLED_PKG_DIR"
    if [ $# -eq 0 ]; then
        python -m pytest -vv "${THISDIR}/tests/"    \
         --cov="${INSTALLED_PKG_DIR}" \
         --cov-report=html \
         --cov-report=term \
         --cov-fail-under=40 || ((PYTEST_EXIT_STATUS+=$?))
        mv htmlcov "${THISDIR}/test-reports/"
    else
        python -m pytest -vv "$@"
    fi
    return $PYTEST_EXIT_STATUS
}
function serve-coverage-report {
    python -m http.server --directory "${THISDIR}/htmlcov" 9090
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
    #load-dotenv : use locally
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
    #load-dotenv : use locally
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
