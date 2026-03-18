#!/usr/bin/env bash
set -euo pipefail

fail=0

legacy_paths=(
  "lib/src/core/pagination_config.dart"
  "lib/src/core/pagination_type.dart"
  "lib/src/adapters/pagination_adapter.dart"
  "lib/src/widgets/pagination_error.dart"
  "lib/src/widgets/pagination_loader.dart"
  "lib/src/widgets/advanced_pagination_list.dart"
  "lib/src/widgets/advanced_pagination_grid.dart"
  "lib/src/widgets/advanced_sliver_list.dart"
  "lib/src/widgets/advanced_sliver_grid.dart"
  "lib/src/core"
  "lib/src/adapters"
)

for path in "${legacy_paths[@]}"; do
  if [[ -e "$path" ]]; then
    echo "Legacy file or folder still present: $path"
    fail=1
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "Remove legacy files or update tool/ci/check_legacy_files.sh if the list changes."
  exit 1
fi

echo "Legacy file check passed."
