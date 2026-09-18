# Game of Life in Fortran und MPI-Parallelisierung

## Features
- MPI-basierte Parallelisierung (Slab-Decomposition entlang der Y-Achse)
- HDF5-Frame-Speicherung
- Konfigurierbare Parameter über `params.json`
- Logfiles in output/.logs

## Voraussetzungen
- **Compiler:** gfortran (programmed in 15.2.0)
- **MPI-Implementation:** OpenMPI
- **HDF5** (mit Fortran-Bindings)
- **Build-System:** Fortran Package Manager (fpm)
### Python
- h5py, numpy, ffmpeg

## Installation & Build
```bash
git clone https://github.com/B-Koberg/gol.git

cd gol

git checkout mpi

./run.sh
```

`run.sh` baut das Projekt mit fpm, führt die Simulation mit 4 MPI-Prozessen aus und erzeugt anschließend das Video.

## Parameter
Alle Einstellungen in `params.json`:

| Parameter | Beschreibung |
|---|---|
| `base_size` | Grid-Basisgröße (nx = ratio_x * base_size, ny = ratio_y * base_size) |
| `ratio_x` / `ratio_y` | Seitenverhältnis |
| `frames` | Anzahl Simulationsschritte |
| `delta_frames` | Alle N-Schritte wird ein Frame gespeichert |
| `periodicity` | Periodische Randbedingungen oder "Tote Wand" |
| `preset` | Anfangsmuster: `"vertical_lines"` oder `"random"` |
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
│   ├── mpi_utils.f90      # MPI: Grid-Zerlegung, Halo-Austausch, Zusammenfügen des Grids
│   └── hdf5_utils.f90     # HDF5: File-Init, Frame-Schreiben, Cleanup
├── make_video.py          # HDF5 -> MP4 via ffmpeg
├── run.sh                 # Build + Run + Video Pipeline
├── params.json            # Konfiguration
└── fpm.toml               # Build-Konfiguration
```

## Anmerkungen
- **FPS**: Das Video ist auf ungefähr 20 Sekunden ausgelegt, mindestens 1 FPS wird verwendet.
- **Ohne Neubau ausführen**: Falls nur die JSON-Datei geändert wurde, kann das vorhandene Programm direkt ausgeführt werden:
```
mpirun --mca btl self,vader -np 4 build/mpifort_*/app/GOL 

python3 make_video.py 

xdg-open ./output/[output_video in params.json]
```
- **Letztes Log ansehen**: `output/.logs/build.log` ist ein Symlink auf das letzte Logfile.