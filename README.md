# BJRencoder

Open source encoding software based on FFMpeg

# Compilation FFMpeg / NVENC ~~+ NVRESIZE~~
> nVidia `nvresize` patch is outdated and not more compatible to the last version of FFmpeg, so it's not included in this documentation.

> Please don't rely on this page: https://developer.nvidia.com/ffmpeg, the implementation is a hack and was never been added to the main FFmpeg tree.

> See:
* https://ffmpeg.org/pipermail/ffmpeg-devel/2015-November/182781.html
* https://ffmpeg.org/pipermail/ffmpeg-devel/2015-November/182784.html
* https://ffmpeg.org/pipermail/ffmpeg-devel/2015-November/182818.html

## Base documentation

* https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
* https://trac.ffmpeg.org/wiki/HWAccelIntro
* [FFMPEG-with-NVIDIA-Acceleration-on-Ubuntu_UG_v01.pdf](http://developer.download.nvidia.com/compute/redist/ffmpeg/1511-patch/FFMPEG-with-NVIDIA-Acceleration-on-Ubuntu_UG_v01.pdf)

## Required softwares

* Linux Mint 18 / Ubuntu 16.04
* [nVidia Video Codec SDK](https://developer.nvidia.com/nvidia-video-codec-sdk)
* [nVidia CUDA SDK](https://developer.nvidia.com/cuda-downloads)

## Steps (respect the order)

###### FFmpeg dependencies

```shell
sudo apt-get -y install autoconf automake build-essential libass-dev libfreetype6-dev libsdl2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev libopenal-dev
```

###### NVENC Headers

```shell
cd Video_Codec_SDK_7.0.1
sudo cp -v Samples/common/inc/*.h /usr/local/include/
make -j 10
cd..
```

###### Yasm `sudo apt-get install yasm`

###### x264 `git clone http://git.videolan.org/git/x264.git`

```shell
cd x264
./configure --disable-cli --enable-static --enable-shared --enable-strip
make -j 10
sudo make install
sudo ldconfig
cd ..
```

###### x265 `sudo apt-get install cmake mercurial`

```shell
hg clone http://hg.videolan.org/x265
cd x265/build
cmake -G "Unix Makefiles"
make -j 10
sudo make install
sudo ldconfig
cd ..
```

###### fdk_aac `git clone https://github.com/mstorsjo/fdk-aac.git`

```shell
autoreconf -fiv
./configure
make -j 10
sudo make install
sudo ldconfig
cd ..
```

###### libmp3_lame `sudo apt-get install libmp3lame-dev`

###### libopus `sudo apt-get install libopus-dev`

###### libvpx `wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.5.0.tar.bz2`

```shell
tar xjvf libvpx-1.5.0.tar.bz2
cd libvpx-1.5.0
./configure --disable-examples --disable-unit-tests
make -j 10
sudo make install
sudo ldconfig
cd ..
```

###### ffmpeg `git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg`

```shell
mkdir -v ffmpeg_build
cd ffmpeg_build
PKG_CONFIG_PATH="./lib/pkgconfig" ../ffmpeg/configure --prefix="./" --pkg-config-flags="--static" --extra-cflags=-I../nvidia/cudautils --extra-ldflags=-L../nvidia/cudautils --enable-nonfree --enable-gpl --enable-avresample --enable-avisynth --enable-openal --enable-opengl --enable-x11grab --enable-nvenc --enable-libx264 --enable-libx265 --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx
make -j 10
make install
```

###### Test install

```shell
./bin/ffmpeg -version
./bin/ffmpeg -encoders | grep -i 'nvidia'
./bin/ffmpeg -filters | grep nvresize
```

## Some CUDA / NVENC Testing
### CPU Based encoding

```shell
time ./bin/ffmpeg -y -i ~/Vidéos/VTS.VOB -t 60 -r 25 -profile:v high -c:v libx264 -fpre ~/Projects/bjrencoder-pro/Presets/libx264-custom.ffpreset -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0:8x8dct=1 -movflags +faststart -map 0:1 -map 0:2 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/VOB_x264_25fps_12500_60s_cpu.mp4
```

### GPU Based encoding

```shell
time ./bin/ffmpeg -y -i ~/Vidéos/VTS.VOB -t 60 -r 25 -profile:v high -c:v h264_nvenc -fpre ~/Projects/bjrencoder-pro/Presets/libx264-custom.ffpreset -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0:8x8dct=1 -movflags +faststart -map 0:1 -map 0:2 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/VOB_x264_25fps_12500_60s_gpu.mp4
```

***

### CPU Based encoding (HEVC)

```shell
time ./bin/ffmpeg -y -i ~/Vidéos/BigBuckBunny/bbb_sunflower_native_60fps_normal.mp4 -t 30 -r 25 -c:v libx265 -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0 -movflags +faststart -map 0:0 -map 0:1 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/bbb_sunflower_native_60fps_normal_EN_x265_25fps_12500_cpu.mkv
```

### GPU Based encoding (HEVC)

>_** Desktop: GPU HEVC works only for graphics cards Geforce GTX 950 series or higher graphics cards (GTX 950, GTX 960, GTX 970, GTX 980, GTX Titan X) **_

>_** Laptop: GTX 965M, 970M, 980M or higher graphics cards **_

```shell
time ./bin/ffmpeg -y -i ~/Vidéos/BigBuckBunny/bbb_sunflower_native_60fps_normal.mp4 -t 30 -r 25 -c:v hevc_nvenc -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0 -movflags +faststart -map 0:0 -map 0:1 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/bbb_sunflower_native_60fps_normal_EN_x265_25fps_12500_gpu.mkv
```

***

### CPU Utilization

* `top`
* `vmstat -w -n 1`

### GPU Utilization

* `nvidia-smi`
* `nvidia-smi dmon -i 0`

***

### CUDA Tools binaries

```shell
cuda-install-samples-8.0.sh <dir>
cd nvidia/NVIDIA_CUDA-8.0_Samples
make -j 10
cd bin/x86_64/linux/release/
./deviceQuery
./bandwidthTest
```

Finished :)
