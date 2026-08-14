#!/home/bastian-koberg/Schreibtisch/Uni/.venv/bin/python
import json

import h5py
import numpy as np
from matplotlib import pyplot as plt
from matplotlib.animation import FuncAnimation


with open("params.json", "r") as f:
    params = json.load(f)

for name, value in params.items():
    globals()[name] = value

fps = frames / 20

with h5py.File(output_file, "r") as f:
    data = np.asarray(f["frames"])

width = round(video_height * ratio_x / ratio_y)

fig, ax = plt.subplots(figsize=(width / 100, video_height / 100), dpi=100)
fig.subplots_adjust(left=0, right=1, top=1, bottom=0)
ax.axis("off")
img = ax.imshow(data[:, :, 0], cmap="gray", interpolation="nearest")


def update(i):
    img.set_data(data[:, :, i])
    return (img,)


ani = FuncAnimation(fig, update, frames=frames, interval=1000 / fps, blit=True)
ani.save(
    output_video,
    writer="ffmpeg",
    fps=fps,
    dpi=100,
    progress_callback=lambda i, n: None,
)
