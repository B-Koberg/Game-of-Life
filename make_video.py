#!/home/bastian-koberg/Schreibtisch/Uni/.venv/bin/python
import json
import subprocess

import h5py
import numpy as np

with open("params.json", "r") as f:
    params = json.load(f)

for name, value in params.items():
    globals()[name] = value

fps = max(1, round(frames / (20 * delta_frames)))
width = round(video_height * ratio_x / ratio_y)

with h5py.File(output_file, "r") as f:
    data = f["frames"]
    data_height, data_width = data.shape[0], data.shape[1]

proc = subprocess.Popen(
    [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-f", "rawvideo",
        "-s", f"{data_width}x{data_height}",
        "-pix_fmt", "gray",
        "-r", str(fps),
        "-i", "-",
        "-vf", f"scale={width}:{video_height}:flags=neighbor",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        output_video,
    ],
    stdin=subprocess.PIPE,
)

with h5py.File(output_file, "r") as f:
    data = f["frames"]
    for i in range(data.shape[2]):
        frame = (data[:, :, i] * 255).astype(np.uint8)
        proc.stdin.write(frame.tobytes())

proc.stdin.close()
proc.wait()
