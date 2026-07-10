# Mandelbrot Berechnung mit Fortran
Mit MPI und/oder OpenMP

## 📋 Inhaltsverzeichnis
- [Features](#-features)
- [Voraussetzungen](#-voraussetzungen)
- [Installation & Build](#-installation--build)
- [Nutzung](#-nutzung)
- [Projektstruktur](#-projektstruktur)
- [Entwicklungsworkflow](#-entwicklungsworkflow)
- [Tests](#-tests)
- [Dokumentation](#-dokumentation)
- [Lizenz](#-lizenz)
- [Autoren & Kontakt](#-autoren--kontakt)

## ✨ Features
- MPI based calculation
- OpenMP based calculation

## 📦 Voraussetzungen
- **Compiler:** gfortran 15.2
- **MPI-Implementation:** OpenMP 4.5
- **Build-System:** Make currently (future fmp und bash)
- **Libraries:** python: numpy, pillow, matplotlib, gc, os, time

## 🛠 Installation & Build
### CMake (Empfohlen)
```bash
git clone https://github.com/B-Koberg/Mandelbrot.git
cd Mandelbrot
git switch feature/openmp oder git switch feature/mpi
make
