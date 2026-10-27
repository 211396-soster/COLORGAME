#!/usr/bin/env python3
"""Baixa texturas PBR CC0 do ambientCG para melhorar o realismo do Color Tintas.

As texturas são baixadas durante o build, não ficam embutidas no código-fonte.
Licença dos materiais: ambientCG, CC0 1.0.
"""
from pathlib import Path
from urllib.request import Request, urlopen
from zipfile import ZipFile
from io import BytesIO

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "tex" / "realism"
ASSETS = {
    "Asphalt003": "Asphalt003_2K-JPG.zip",
    "PavingStones002": "PavingStones002_2K-JPG.zip",
}

def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    for asset_id, filename in ASSETS.items():
        url = f"https://ambientcg.com/get?file={filename}"
        request = Request(url, headers={"User-Agent": "ColorTintas-AssetBuilder/1.0"})
        print(f"Baixando material CC0: {asset_id} (2K JPG)...", flush=True)
        with urlopen(request, timeout=90) as response:
            payload = response.read()
        with ZipFile(BytesIO(payload)) as archive:
            prefix = f"{asset_id}_2K-JPG_"
            wanted = ("_Color.jpg", "_NormalGL.jpg", "_Roughness.jpg")
            found = set()
            for member in archive.namelist():
                name = Path(member).name
                if name.startswith(prefix) and name.endswith(wanted):
                    target = DEST / name
                    target.write_bytes(archive.read(member))
                    found.add(name.rsplit("_", 1)[-1])
                    print(f"  OK {target.relative_to(ROOT)} ({target.stat().st_size // 1024} KB)", flush=True)
            if not any(Path(member).name.startswith(prefix) and Path(member).name.endswith("_Color.jpg") for member in archive.namelist()):
                raise RuntimeError(f"Nenhuma textura de cor encontrada no pacote {filename}")
    print("Texturas PBR prontas para o importador do Godot.", flush=True)

if __name__ == "__main__":
    main()
