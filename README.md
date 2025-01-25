# HandBrake, Dockerized with NVEnc, Dolby Vision, and Intel QuickSync – in the browser.
A Docker container compiled for NVEnc for NVIDIA GPUs, libdovi (for Dolby Vision transcodes), and Intel QuickSync – that runs in the browser. This build also resolves several GTK3 bugs which cause the UI to hang/freeze. Based on [zocker160/handbrake-nvenc:18x](https://github.com/zocker-160/handbrake-nvenc-docker).

<img src="https://handbrake.fr/docs/assets/images/icon@2x.png" width="100" alt="HandBrake logo" /> ![+](https://github.com/user-attachments/assets/18cea26f-88b2-4ea0-8182-d6558ea1ca58)
 <img src="https://github.com/user-attachments/assets/c195e982-74b3-4776-bfcb-7eae0ee0d8c3" width="100" alt="Docker logo" />


## Requirements

- An NVIDIA GPU that [supports NVEnc](https://developer.nvidia.com/video-encode-and-decode-gpu-support-matrix-new)
- A Linux OS*
  - As of Jan 2025, this has only been tested on Ubuntu 20.04, 22.04, and 24.04. It may or may not run on Windows and other distros.
- NVIDIA drivers version 560 or newer
  - Note: versions 545 through 555 reintroduced an old driver bug that breaks the bitrate calculation math, resulting in transcodes with wildly different bitrates than specified.
  - As of Jan 2025, version 565 works well (`sudo ubuntu-drivers install nvidia:565`)
- A NVIDIA-supported docker environment (there are several guides out there, but [this one](https://medium.com/@u.mele.coding/a-beginners-guide-to-nvidia-container-toolkit-on-docker-92b645f92006) is comprehensive and concise). If you intend to use `docker compose` (recommended), there are [additional steps](https://docs.docker.com/compose/how-tos/gpu-support/) to enable the CUDA runtime for your containers.
  - (See "Installation & Getting Started")

## Installation & Getting Started

### Configure your Docker environment

(Podman also works if running in Docker-compatible mode)

1. Install the [NVIDIA container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#installing-with-apt)
2. Configure it for [Docker](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuring-docker) or [Podman](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html#configuring-podman) (in Docker-compatible mode)
  You should have the following in your `/etc/docker/daemon.json`:
  ```json
  {
      "runtimes": {
          "nvidia": {
              "args": [],
              "path": "nvidia-container-runtime"
          }
      }
  }
  ```

3. Run a test container `sudo docker run --rm --gpus all nvidia/cuda:12.6.3-base-ubuntu24.04 nvidia-smi` – you should see the `nvidia-smi` output similar to the output shown in the changelog below.

### Build and run the HandBrake container

4. Clone this repo or download an archive, and extract to a location of your choice.
5. Using `docker compose` (easy), simply:

   ```$ cd <path/to/repo>``` then 

   ```docker compose -f docker-compose.handbrake.yml up -d --build --force-recreate builder handbrake```

   This can take a while, as it has to compile rust and handbrake from source, so be patient.

   If you prefer to build the container manually (hard), you'll need to follow the instructions in the [upstream zocker-160 repo](https://github.com/zocker-160/handbrake-nvenc-docker) and reverse-engineer the compose file (don't forget the shared build volume!).

6. Connect to http://localhost:5800 and 🎉

### Configuration

7. Configuration options are documented in the [upstream zocker-160 repo](https://github.com/zocker-160/handbrake-nvenc-docker).

## Changelog

### HandBrake 1.9.0

```
Runtime environment: Native
Commit hash: 77f199ab0
Build date: 2024-08-07 17:31:52
GTK version: 4.6.9 (built against 4.6.9)
GLib version: 2.72.4 (built against 2.72.4)
Built with support for:
- Intel QuickSync
- Nvidia NVEnc
- x265
- libdovi
```

Ubuntu 22.04
Docker version 27.3.1, build ce12230
NVIDIA UNIX x86_64 Kernel Module  565.57.01

```sh
$ cat /proc/driver/nvidia/version
NVRM version: NVIDIA UNIX x86_64 Kernel Module  565.57.01  Thu Oct 10 12:29:05 UTC 2024
GCC version:  gcc version 12.3.0 (Ubuntu 12.3.0-1ubuntu1~22.04)
```

```sh
$ nvidia-smi

+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 565.57.01              Driver Version: 565.57.01      CUDA Version: 12.7     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 2060        On  |   00000000:01:00.0 Off |                  N/A |
| N/A   50C    P0             23W /  115W |     482MiB /   6144MiB |     14%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
                                                                                         
+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI        PID   Type   Process name                              GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A      1975      G   /usr/lib/xorg/Xorg                             56MiB |
|    0   N/A  N/A      2865      G   /usr/bin/gnome-shell                            5MiB |
|    0   N/A  N/A     14848    C+G   ...libexec/gnome-remote-desktop-daemon         83MiB |
|    0   N/A  N/A   1237291      C   /usr/bin/ghb                                  330MiB |
+-----------------------------------------------------------------------------------------+
```
