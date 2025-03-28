# HunyuanVideoGP: Large Video Generation for the GPU Poor

Containerized version of the Hunyuan Video generator. It is based on the HunyuanVideo project, with deepmeepbeep's optimizations for the GPU-poor. It lets you run a quantized version on your smaller GPU, e.g. with 12GB of VRAM or even less.

Tested on RTX 3060 12GB, RTX 3090 TI, L40 and H100. On low VRAM cards, it may still work, though there will be limitations to video quality and inference speed. Currently, only NVIDIA CPUs are supported, as the code relies on CUDA for processing.

During first start-up, the container will acquire the latest model and code from [deepmeepbeep's repo](https://github.com/deepbeepmeep/HunyuanVideoGP) and the latest tencent/HunyuanVideo model from [Huggingface](https://huggingface.co/tencent/HunyuanVideo).

## Disk Size and Startup Time
The container requires considerable disk space for storage of the AI models. On my setup, I observe 7GB for the Docker image itself, plus 15GB for cached data. Building the cache will happen the first time you start the container, which can easily take 20 minutes or more. After that, any restart should be faster.

It may be advisable to store the cache outside of the container, e.g. by mounting a volume to /workspace.

## Variables
HVGP_AUTO_UPDATE: Automatically updates the models and inference scripts to the latest version upon container start-up (default: 0).
 - 0: Don't update automatically. Use the scripts that are bundled.
 - 1: Update and use the latest features/models, but also accept that this may bring breaking changes.

This container does not provide much configuration, as many other configuration parameters can be changed through the web interface.

### Fixing Caching Issues
As the container updates the models to the latest available version, there is no guarantee that the cached files from previous start-ups are compatible with updated versions. I haven't encountered any issues yet. However, should you run into issues, just removing the cache folder will cause the startup script to rebuild the cache from scratch, thereby fixing any inconsistencies.

## Command Reference

### Build the Container
Building the container is straightforward. It will build the container based on NVIDIA's CUDA development container and add required Python dependencies for bootstrapping HunyuanVideoGP.
```bash
docker build -t olilanz/ai-hunyuan-video-gp .
```

### Running the Container
On my setup, I am using the following parameters:
```bash
docker run -it --rm --name ai-hunyuan-video-gp \
  --shm-size 24g --gpus all \
  -p 7861:7860 \
  -v /mnt/cache/appdata/ai-hunyuan-video-gp:/workspace \
  -e HVGP_AUTO_UPDATE=1 \
  olilanz/ai-hunyuan-video-gp
```
Note that you need to have an NVIDIA GPU installed, including all dependencies for Docker.

### Environment Reference
I am running on a computer with an AMD Ryzen 7 3700X, 128GB RAM, an RTX 3090 TI with 24GB VRAM. CPU and RAM are plentiful. It runs stable in that configuration. The web UI handles out-of-memory errors gracefully. In case this happens, you can easily tweak the settings to balance the quality/speed/VRAM requirements.

A video for 5 seconds in 960x544 (16:9, 540p) takes me about 15 minutes to render - with 40 inference steps and other high-quality settings.

## Resources
* For the GPU-Poor: https://github.com/deepbeepmeep/HunyuanVideoGP
* For the non-GPU-Poor: https://github.com/Tencent/HunyuanVideo
