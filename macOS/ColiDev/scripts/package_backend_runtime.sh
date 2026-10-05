#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "$script_dir/../../.." && pwd)"
app_bundle="${1:?usage: package_backend_runtime.sh /path/to/ColiDev.app}"
resources="$app_bundle/Contents/Resources"
destination="$resources/ColiDevBackend"

if [[ ! -d "$resources" ]]; then
    echo "Xcode app bundle has no Contents/Resources: $app_bundle" >&2
    exit 1
fi
if [[ -e "$destination" ]]; then
    echo "Refusing to overwrite an existing backend bundle: $destination" >&2
    exit 1
fi

build_root="$(mktemp -d "${TMPDIR:-/tmp}/colidev-backend-build.XXXXXX")"
trap 'rm -rf "$build_root"' EXIT

python3 -m PyInstaller \
    --noconfirm \
    --clean \
    --onedir \
    --name ColiDevBackend \
    --paths "$project_root/01_Projects" \
    --hidden-import keyring.backends.macOS \
    --add-data "$project_root/01_Projects/ui.html:." \
    --distpath "$build_root/dist" \
    --workpath "$build_root/work" \
    --specpath "$build_root/spec" \
    "$project_root/01_Projects/orchestrator.py"

mkdir -p "$resources"
cp -R "$build_root/dist/ColiDevBackend" "$destination"
test -x "$destination/ColiDevBackend"
test -f "$destination/_internal/ui.html"
echo "Bundled local backend into $destination"
