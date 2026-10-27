#!/usr/bin/env python3
"""Download small CC0 glTF models from Poly Haven for the Color Tintas build.

Poly Haven assets are CC0 1.0. The build downloads only the 1K model package
and its dependencies; downloaded binaries are not committed to Git.
"""
from __future__ import annotations
import json
from pathlib import Path, PurePosixPath
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from urllib.parse import urlparse
from zipfile import ZipFile
from io import BytesIO

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "realism"
API = "https://api.polyhaven.com"
ASSETS = {
    "covered_car": "Covered Car (static scenery prop)",
    "street_lamp_01": "Street Lamp 01",
    "tree_small_02": "Tree Small 02",
}

def fetch_json(url: str):
    req = Request(url, headers={"User-Agent": "ColorTintas-AssetBuilder/1.0"})
    with urlopen(req, timeout=45) as response:
        return json.loads(response.read().decode("utf-8"))

def download(url: str) -> bytes:
    req = Request(url, headers={"User-Agent": "ColorTintas-AssetBuilder/1.0"})
    with urlopen(req, timeout=90) as response:
        return response.read()

def safe_rel(value: str) -> Path:
    path = PurePosixPath(value.replace("\\", "/"))
    if path.is_absolute() or ".." in path.parts:
        raise RuntimeError(f"Unsafe asset path from API: {value}")
    return Path(*path.parts)

def main_file_and_includes(files: dict):
    gltf_root = files.get("gltf") or files.get("glTF")
    if not isinstance(gltf_root, dict):
        raise RuntimeError("Poly Haven did not provide a glTF download")
    # Prefer the compact 1K package; fall back to the first available glTF package.
    variant = gltf_root.get("1k")
    if not isinstance(variant, dict):
        variant = next((v for v in gltf_root.values() if isinstance(v, dict)), None)
    if not isinstance(variant, dict):
        raise RuntimeError("No usable glTF variant was found")
    main = variant.get("gltf") or variant.get("glb")
    if isinstance(main, dict) and main.get("url"):
        return main, variant.get("include", {})
    # Some assets expose the main file nested one level deeper.
    def walk(node):
        if isinstance(node, dict):
            if node.get("url") and urlparse(node["url"]).path.lower().endswith((".gltf", ".glb")):
                yield node
            for value in node.values():
                yield from walk(value)
        elif isinstance(node, list):
            for value in node:
                yield from walk(value)
    candidates = list(walk(variant))
    if not candidates:
        raise RuntimeError("No .gltf/.glb file found in Poly Haven response")
    main = next((x for x in candidates if urlparse(x["url"]).path.lower().endswith(".glb")), candidates[0])
    return main, variant.get("include", {})

def install_asset(asset_id: str, display_name: str, manifest: dict):
    target = DEST / asset_id
    target.mkdir(parents=True, exist_ok=True)
    files = fetch_json(f"{API}/files/{asset_id}")
    main, includes = main_file_and_includes(files)
    main_name = Path(urlparse(main["url"]).path).name
    if not main_name:
        raise RuntimeError(f"Main file has no filename for {asset_id}")
    main_path = target / main_name
    if not main_path.exists() or main_path.stat().st_size == 0:
        main_path.write_bytes(download(main["url"]))
    # glTF files reference sidecar buffers/textures by relative path. Keep those paths.
    if isinstance(includes, dict):
        for rel_name, record in includes.items():
            if not isinstance(record, dict) or not record.get("url"):
                continue
            rel = safe_rel(rel_name)
            out = target / rel
            out.parent.mkdir(parents=True, exist_ok=True)
            if not out.exists() or out.stat().st_size == 0:
                out.write_bytes(download(record["url"]))
    manifest[asset_id] = {
        "name": display_name,
        "path": f"res://assets/realism/{asset_id}/{main_name}",
        "source": f"https://polyhaven.com/a/{asset_id}",
        "license": "CC0 1.0",
    }
    print(f"Installed {display_name}: {main_path.relative_to(ROOT)} ({main_path.stat().st_size // 1024} KB)", flush=True)

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for asset_id, display_name in ASSETS.items():
        print(f"Fetching {display_name} from Poly Haven...", flush=True)
        try:
            install_asset(asset_id, display_name, manifest)
        except Exception as exc:
            # External asset endpoints may change; keep procedural fallbacks usable.
            print(f"WARNING: skipped optional model {asset_id}: {exc}", flush=True)
    (DEST / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Manifest written to {(DEST / 'manifest.json').relative_to(ROOT)}", flush=True)

if __name__ == "__main__":
    main()
