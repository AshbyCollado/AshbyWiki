#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
vault_path="${1:-"$script_dir/../content"}"
check_only=false
if [[ "${1:-}" == "--check" ]]; then check_only=true; vault_path="${2:-"$script_dir/../content"}"; fi
lock="$script_dir/obsidian-plugins.lock.json"
plugin_root="$vault_path/.obsidian/plugins"
community="$vault_path/.obsidian/community-plugins.json"

command -v python3 >/dev/null || { echo "Required command 'python3' was not found." >&2; exit 1; }
[[ -d "$vault_path" ]] || { echo "Vault directory does not exist: $vault_path" >&2; exit 1; }

if $check_only; then
  python3 - "$lock" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding="utf-8"))
for p in data["plugins"]: print(f"- {p['id']} {p['version']} ({p['repository']})")
PY
  exit 0
fi

run="$(mktemp -d "${TMPDIR:-/tmp}/ashby-plugins.XXXXXX")"
stage="$run/stage"; backup="$run/backup"; mkdir -p "$stage" "$backup" "$plugin_root"
cleanup(){ rm -rf "$run"; }
trap cleanup EXIT

python3 - "$lock" "$run" "$stage" "$plugin_root" "$community" <<'PY'
import hashlib, json, pathlib, shutil, sys, urllib.request

lock_path, run, stage, plugin_root, community = map(pathlib.Path, sys.argv[1:])
data=json.loads(lock_path.read_text(encoding="utf-8"))
def download(url, path):
    request=urllib.request.Request(url, headers={"User-Agent":"AshbyWiki plugin installer"})
    with urllib.request.urlopen(request) as source, path.open("wb") as target: shutil.copyfileobj(source, target)
def verify(path, expected, label):
    if expected:
        actual=hashlib.sha256(path.read_bytes()).hexdigest()
        if actual.lower() != expected.lower(): raise RuntimeError(f"SHA-256 mismatch for {label}")
for plugin in data["plugins"]:
    out=stage/plugin["id"]; out.mkdir(parents=True)
    for asset in plugin["assets"]:
        name,url=asset["name"],asset["url"]
        target=run/(plugin["id"]+"-"+name); download(url,target); verify(target, asset.get("sha256"), plugin["id"]+"/"+name); shutil.copy2(target,out/name)
    manifest=json.loads((out/"manifest.json").read_text(encoding="utf-8"))
    if manifest.get("id") != plugin["id"] or manifest.get("version") != plugin["version"]: raise RuntimeError(f"Manifest mismatch for {plugin['id']}")
    for name in ("main.js","manifest.json","styles.css"):
        if not (out/name).is_file(): raise RuntimeError(f"Release for {plugin['id']} is missing {name}")

existing=[]
if community.is_file():
    parsed=json.loads(community.read_text(encoding="utf-8")); existing=parsed if isinstance(parsed,list) else []
ids=[]
for value in existing+[p["id"] for p in data["plugins"]]:
    if isinstance(value,str) and value not in ids: ids.append(value)
(run/"community-plugins.json").write_text(json.dumps(ids,indent=2)+"\n",encoding="utf-8")
moved=[]
try:
    for plugin in data["plugins"]:
        dest=plugin_root/plugin["id"]; old=backup/plugin["id"]
        if dest.exists(): shutil.move(str(dest),str(old)); moved.append(plugin["id"])
        shutil.move(str(stage/plugin["id"]),str(dest))
    if community.exists(): shutil.move(str(community),str(backup/"community-plugins.json"))
    shutil.move(str(run/"community-plugins.json"),str(community))
except Exception:
    for plugin in data["plugins"]:
        dest=plugin_root/plugin["id"]; old=backup/plugin["id"]
        if dest.exists(): shutil.rmtree(dest)
        if old.exists(): shutil.move(str(old),str(dest))
    old=backup/"community-plugins.json"
    if old.exists():
        if community.exists(): community.unlink()
        shutil.move(str(old),str(community))
    raise
print(f"Installed and verified {len(data['plugins'])} pinned Obsidian plugins in {plugin_root}")
PY
