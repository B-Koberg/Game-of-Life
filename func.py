# func.py
from datetime import datetime
import os
import gc
import glob
import numpy as np
from PIL import Image
import matplotlib.cm as cm
import json

def now_hms() -> str:
    return datetime.now().strftime("%H:%M:%S")

def find_input_files(pattern: str = "output/mandelbrot_output_*.bin"):
    files = sorted(glob.glob(pattern))
    if not files:
        raise FileNotFoundError(f"Keine Dateien gefunden: {pattern}")
    return files


def read_all_infos(files):
    params = json.load(open("params.json", "r"))
    return params

def build_global_array(params, files):
    nx = int(params["ratio_x"] * params["base_size"])
    ny = int(params["ratio_y"] * params["base_size"])
    max_iter = int(params["max_iter"])

    print(f"({now_hms()}) nx={nx}, ny={ny}, max_iter={max_iter}")
    print(f"({now_hms()}) Baue globales Array aus {len(files)} Blöcken...")
    global_arr = np.empty((nx, ny), dtype=np.int32, order="F")

    col_start = 0
    bytes_per_elem = np.dtype(np.int32).itemsize

    for fname in files:
        print(f"({now_hms()}) Lese {fname}...")
        # Datei komplett als int32 einlesen (ohne count) und lokale Breite aus Länge bestimmen
        with open(fname, "rb") as f:
            data = np.fromfile(f, dtype=np.int32)  # lese alle verbleibenden Elemente

        if data.size == 0:
            raise ValueError(f"Datei {fname} enthält keine Daten")
        
        if data.size % nx != 0:
            raise ValueError(f"Datei {fname}: Datenlänge {data.size} ist kein Vielfaches von nx={nx}")

        local_ny = data.size // nx
        print(f"({now_hms()}) Gefundene Elemente: {data.size}, daraus folgt local_ny={local_ny}")
        print(f"({now_hms()}) Schreibe cols {col_start}:{col_start + local_ny}")

        block = data.reshape((nx, local_ny), order="F")
        global_arr[:, col_start:col_start + local_ny] = block
        col_start += local_ny

        # aufräumen
        del data, block
        gc.collect()

    if col_start != ny:
        print(f"({now_hms()}) Warnung: erwartete ny={ny}, gefüllte Spalten={col_start}")

    return global_arr, nx, ny, max_iter


def compute_block_height(ny: int, target: int = 1000) -> int:
    possible_block_h = [ny / i for i in [0.0625, 0.125, 0.25, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 35]]
    min_idx = int(np.argmin([abs(bh - target) for bh in possible_block_h]))
    block_h = int(round(possible_block_h[min_idx])) + 1
    return max(1, block_h)

def create_image_from_array(global_arr, nx, ny, max_iter, out_path):
    arr_view = global_arr.reshape((nx, ny), order="F").T

    gmin = 0
    gmax = max_iter
    use_log = (gmax > gmin)

    block_h = compute_block_height(ny)
    print(f"({now_hms()}) Erstelle Bild mit Pixelreihen im Arbeitsspeicher {block_h} von {ny} Pixelreihen insgesamt...")
    img = Image.new("RGB", (nx, ny))

    for y0 in range(0, ny, block_h):
        y1 = min(y0 + block_h, ny)
        block = arr_view[y0:y1, :].astype(np.int32)
        mask_max = (block == max_iter)

        if not use_log:
            norm = np.zeros_like(block, dtype=np.float32)
        else:
            block_f = block.astype(np.float32)
            numer = block_f - float(gmin) + 1.0
            denom = float(gmax) - float(gmin) + 1.0
            norm = np.log(numer) / np.log(denom)
            norm[mask_max] = 0.0

        rgb_block = (cm.inferno(norm)[:, :, :3] * 255).astype("uint8")
        rgb_block[mask_max, :] = 0
        img.paste(Image.fromarray(rgb_block), (0, y0))

        del block, norm, rgb_block, mask_max
        try:
            del block_f
        except NameError:
            pass
        gc.collect()
        print(f"({now_hms()}) Progress {y1}/{ny} Pixelreihen verarbeitet...")

    print(f"({now_hms()}) Bild erstellt, speichere: {out_path}")
    img.save(out_path)
    del img, arr_view, global_arr
    gc.collect()

