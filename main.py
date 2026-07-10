# main.py
import time
from func import (
    now_hms,
    find_input_files,
    read_all_infos,
    build_global_array,
    create_image_from_array,
)

def main():
    start_time = time.time()
    print(f"({now_hms()}) Starte Plot-Erstellung...")

    files = find_input_files("output/mandelbrot_output_*.bin")
    print(f"({now_hms()}) Gefundene Dateien: {len(files)}")

    params = read_all_infos(files)
    global_arr, nx, ny, max_iter = build_global_array(params, files)

    out_path =  params['output_png']
    create_image_from_array(global_arr, nx, ny, max_iter, out_path)

    print(f"({now_hms()}) Fertig: {out_path} gespeichert. Dauer: {time.time() - start_time:.2f}s")

if __name__ == "__main__":
    main()
