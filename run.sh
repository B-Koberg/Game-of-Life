#!/usr/bin/env bash

export FPM_FC="gfortran"
export FPM_FFLAGS="-fopenmp"
export OMP_NUM_THREADS=8

# Logverzeichnis
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="build_${TIMESTAMP}.log"
LOGDIR="output/.logs"
mkdir -p "$LOGDIR"
LOGPATH="${LOGDIR}/${LOGFILE}"

# Alle Ausgaben in die Logdatei schreiben und gleichzeitig auf der Konsole anzeigen.
exec > >(tee -a "$LOGPATH") 2>&1

# Startzeit in Millisekunden
START_MS=$(($(date +%s%N) / 1000000))

echo "=== Build gestartet: $(date '+%Y-%m-%d %H:%M:%S') ==="

#fpm build -V

fpm run 

# Zeit nach der Berechnung
MID_MS=$(($(date +%s%N)/1000000))
ELAPSED_MS=$((MID_MS - START_MS))

hours=$((ELAPSED_MS / 3600000))
mins=$(((ELAPSED_MS % 3600000) / 60000))
secs=$(((ELAPSED_MS % 60000) / 1000))
msecs=$((ELAPSED_MS % 1000))

printf "=== Berechnung fertig: %s, Dauer: %02d:%02d:%02d.%03d ===\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$hours" "$mins" "$secs" "$msecs"

#python3 make_video.py

# Gesamtzeit
END_MS=$(($(date +%s%N)/1000000))
TOTAL_MS=$((END_MS - START_MS))

hours=$((TOTAL_MS / 3600000))
mins=$(((TOTAL_MS % 3600000) / 60000))
secs=$(((TOTAL_MS % 60000) / 1000))
msecs=$((TOTAL_MS % 1000))

printf "=== Komplett fertig: %s, Dauer: %02d:%02d:%02d.%03d ===\n" \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$hours" "$mins" "$secs" "$msecs"

#xdg-open output/frames.mp4

# Symlink auf die aktuelle Logdatei
ln -sf "$(realpath "$LOGPATH")" "${LOGDIR}/build.log"