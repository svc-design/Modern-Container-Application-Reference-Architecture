#!/usr/bin/env bash
set -euo pipefail

contract_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PYTHONDONTWRITEBYTECODE=1
python_bin="${PYTHON_BIN:-python3}"

"${python_bin}" -m unittest discover \
  -s "${contract_dir}/tests" \
  -p 'test_*.py' \
  -v
