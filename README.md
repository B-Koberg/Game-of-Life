# Game of Life in Fortran mit OpenMP-Parallelisierung

## Features
- OpenMP-basierte Parallelisierung (Shared Memory)
- HDF5-Frame-Speicherung
- Konfigurierbare Parameter über `params.json`
- Logfiles in output/.logs

## Voraussetzungen
- **Compiler:** gfortran (programmed in 15.2.0) mit OpenMP-Support
- **HDF5** (mit Fortran-Bindings)
- **Build-System:** Fortran Project Mangager (fpm)
### Python
- h5py, numpy, ffmpeg

## Installation & Build
```bash
git clone https://github.com/B-Koberg/gol.git

cd gol

./run.sh
```

`run.sh` baut das Projekt mit fpm (gfortran + `-fopenmp`), führt die Simulation aus und erzeugt anschließend das Video.

## Parameter
Alle Einstellungen in `params.json`:

| Parameter | Beschreibung |
|---|---|
| `base_size` | Grid-Basisgröße (nx = ratio_x * base_size, ny = ratio_y * base_size) |
| `ratio_x` / `ratio_y` | Seitenverhältnis |
| `frames` | Anzahl Simulationsschritte |
| `delta_frames` | Alle N-Schritte wird ein Frame gespeichert |
| `periodicity` | Periodische Randbedingungen oder "Tote Wand" |
| `preset` | Anfangsmuster: Bisher möglich `"verticle_lines"` oder `"random"` |
| `video_height` | Video-Auflösung in Pixel (Höhe, Breite wird aus Verhältnis berechnet) |
| `output_file` | HDF5-Ausgabepfad |
| `output_video` | Video-Ausgabepfad |

## Projektstruktur
```
gol/
├── app/main.f90           # Hauptprogramm
├── src/
│   ├── GOL.f90            # GoL-Logik (Init, Step, Swap, Neighbor-Counting)
│   ├── parameters.f90     # JSON-Parameter laden
│   └── hdf5_utils.f90     # HDF5: File-Init, Frame-Schreiben, Cleanup
├── make_video.py          # HDF5 -> MP4 via ffmpeg
├── run.sh                 # Build + Run + Video Pipeline
├── params.json            # Konfiguration
└── fpm.toml               # Build-Konfiguration
```

## Anmerkungen
- **FPS**: Die FPS des Videos sind so programmiert, dass das video immer ca. 20 Sekunden lang ist oder 1 FPS angenommen wird.
- **Ohne Build ausführen**: Falls nur Parameter in der JSON-Datei geändert wurde, reicht es die Datei nochmal auszuführen ohne das Projekt komplett zu compelieren:
```
./build/gfortran_*/app/GOL

python3 make_video.py 

xdg-open ./output/[output_video in params.json]
```
- **Log Files**: Virtual Link ./output/.logs/build.log zum letzten Log  