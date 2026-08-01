#!/usr/bin/env python3
"""Prepara gli asset incorporabili dell'infografica dell'orario.

Prende le pose di Chigio da `assets/images/` e i font di marca da
`assets/fonts/`, li riduce al minimo necessario per una pagina web e li
scrive in `prototypes/assets-infografica/`, dove `build_infografica.mjs`
li trasforma in data URI.

- immagini: ritaglio del trasparente, lato lungo a 300 px, WebP q82
- font: sottoinsieme latino/italiano in WOFF2 (da ~63 KB a ~8 KB l'uno)

Dipendenze:  pip install pillow fonttools brotli
Uso:         python3 scripts/prepare_infografica_assets.py
"""

from __future__ import annotations

import io
import subprocess
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:  # pragma: no cover - messaggio d'aiuto
    sys.exit("Manca Pillow: pip install pillow fonttools brotli")

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "prototypes" / "assets-infografica"

# Pose usate nell'infografica, nell'ordine in cui compaiono.
POSE = [
    "chigio-ciao",          # hero, saluto
    "chigio-orologio",      # la giornata tipo
    "chigio-corre",         # timbratura
    "chigio-caffe",         # regola delle 9 ore
    "chigio-calcolatrice",  # il calcolo
    "chigio-bavaglino",     # buono pasto
    "chigio-lista",         # maggior presenza
    "chigio-ok",            # tipi di giornata + piede
    "chigio-timer",         # come funziona l'app
    "chigio-festeggia",     # avviso finale
]

FONT = {
    "jakarta-400": "PlusJakartaSans-Regular.ttf",
    "jakarta-600": "PlusJakartaSans-SemiBold.ttf",
    "jakarta-700": "PlusJakartaSans-Bold.ttf",
    "jakarta-800": "PlusJakartaSans-ExtraBold.ttf",
    "roboto-400": "Roboto-Regular.ttf",
}

# Latino di base, accenti italiani, punteggiatura tipografica e simboli usati
# nelle formule (≥ ≤ − · → ✓).
GLIFI = (
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    " .,;:!?'\"()[]{}/\\|-_+=*&%#@$€°<>~^`"
    "àèéìíòóùúÀÈÉÌÒÙâêîôûäëïöüçÇñÁÍÓÚÂÊÎÔÛÄËÏÖÜ"
    "—–…·•→←↑↓✓✔✕×±≥≤≈½¼¾№§©®™"
)

LATO_LUNGO = 300


def prepara_immagini() -> None:
    for nome in POSE:
        sorgente = ROOT / "assets" / "images" / f"{nome}.png"
        immagine = Image.open(sorgente).convert("RGBA")
        riquadro = immagine.getbbox()
        if riquadro:
            immagine = immagine.crop(riquadro)
        larghezza, altezza = immagine.size
        fattore = LATO_LUNGO / max(larghezza, altezza)
        immagine = immagine.resize(
            (max(1, round(larghezza * fattore)), max(1, round(altezza * fattore))),
            Image.LANCZOS,
        )
        buffer = io.BytesIO()
        immagine.save(buffer, "WEBP", quality=82, method=6)
        destinazione = OUT / f"{nome}.webp"
        destinazione.write_bytes(buffer.getvalue())
        print(f"  {destinazione.name:28} {len(buffer.getvalue()) / 1024:6.1f} KB")


def prepara_font() -> None:
    unicodi = ",".join(f"U+{ord(c):04X}" for c in sorted(set(GLIFI)))
    for alias, file in FONT.items():
        destinazione = OUT / f"{alias}.woff2"
        subprocess.run(
            [
                "pyftsubset",
                str(ROOT / "assets" / "fonts" / file),
                f"--unicodes={unicodi}",
                "--layout-features=kern,liga,ccmp,locl,tnum",
                "--flavor=woff2",
                "--desubroutinize",
                f"--output-file={destinazione}",
            ],
            check=True,
        )
        print(f"  {destinazione.name:28} {destinazione.stat().st_size / 1024:6.1f} KB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    print("Pose di Chigio → WebP 300 px")
    prepara_immagini()
    print("Font di marca → WOFF2 sottoinsieme")
    prepara_font()
    print(f"\nFatto. Ora: node scripts/build_infografica.mjs")


if __name__ == "__main__":
    main()
