# ai-hunyuan-video-gp
HunyuanVideoGP: Large Video Generation for the GPU Poor

```bash
docker build -t olilanz/ai-hunyuan-video-gp .
```

```bash
docker run -it --rm --name ai-hunyuan-video-gp \
  --shm-size 24g --gpus all \
  -p 7861:7860 \
  -v /mnt/cache/appdata/ai-hunyuan-video-gp:/workspace \
  --network host \
  olilanz/ai-hunyuan-video-gp
```