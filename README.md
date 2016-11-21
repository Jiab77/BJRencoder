# BJRencoder
Open source encoding software based on FFMpeg

# Compilation FFMpeg / NVENC | NVRESIZE

## Base documentation
* <https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu>
* <https://trac.ffmpeg.org/wiki/HWAccelIntro>
* [FFMPEG-with-NVIDIA-Acceleration-on-Ubuntu_UG_v01.pdf](http://developer.download.nvidia.com/compute/redist/ffmpeg/1511-patch/FFMPEG-with-NVIDIA-Acceleration-on-Ubuntu_UG_v01.pdf)

## Required softwares
* [nVidia Video Codec SDK](https://developer.nvidia.com/nvidia-video-codec-sdk)
* [nVidia CUDA SDK](https://developer.nvidia.com/cuda-downloads)

## Steps

1. #### YASM `sudo apt-get install yasm`

2. #### x264 `git clone http://git.videolan.org/git/x264.git`
	1. cd x264
	2. ./configure --disable-cli --enable-static --enable-shared --enable-strip
	3. make -j 10
	4. sudo make install
	5. sudo ldconfig
	6. cd ..

3. #### x265 `sudo apt-get install cmake mercurial`
	1. hg clone http://hg.videolan.org/x265
	2. cd /x265/build
	3. cmake -G "Unix Makefiles"
	4. make
	5. sudo make install
	6. sudo ldconfig
	7. cd ..

4. #### fdk_aac `git clone https://github.com/mstorsjo/fdk-aac.git`
	1. autoreconf -fiv
	2. ./configure
	3. make
	4. sudo make install
	5. sudo ldconfig
	6. cd ..
5. #### libmp3_lame `sudo apt-get install libmp3lame-dev`
6. #### libopus `sudo apt-get install libopus-dev`
7. #### libvpx `wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-1.5.0.tar.bz2`
	1. tar xjvf libvpx-1.5.0.tar.bz2
	2. cd libvpx-1.5.0
	3. ./configure --disable-examples --disable-unit-tests
	4. make
	5. sudo make install
	6. sudo ldconfig
	7. cd ..
8. #### ffmpeg `git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg`
	1. mkdir -v ffmpeg_build
	2. cd ffmpeg_build
	3. ../ffmpeg/configure --prefix="$PWD" --enable-nonfree --enable-nvenc --extra-cflags=-I../cudautils --extra-ldflags=-L../cudautils --enable-gpl --enable-libx264 --enable-libx265 --enable-libass --enable-libfdk-aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libtheora --enable-libvorbis --enable-libvpx
	4. make -j 10
	5. make install
	6. hash -r
9. #### Test install
	1. `./ffmpeg -version`
	2. `./ffmpeg -encoders | grep -i 'nvidia'`
	3. `./ffmpeg -filters | grep nvresize`

## Some CUDA / NVENC Testing
### CPU Based encoding
	time ./ffmpeg -y -i ~/Vidéos/VTS.VOB -t 60 -r 25 -profile:v high -c:v libx264 -fpre ~/Projects/bjrencoder-pro/Presets/libx264-custom.ffpreset -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0:8x8dct=1 -movflags +faststart -map 0:1 -map 0:2 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/VOB_x264_25fps_12500_60s_cpu.mp4
### GPU Based encoding
	time ./ffmpeg -y -i ~/Vidéos/VTS.VOB -t 60 -r 25 -profile:v high -c:v h264_nvenc -fpre ~/Projects/bjrencoder-pro/Presets/libx264-custom.ffpreset -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0:8x8dct=1 -movflags +faststart -map 0:1 -map 0:2 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/VOB_x264_25fps_12500_60s_gpu.mp4
***
### CPU Based encoding (HEVC)
	time ./ffmpeg -y -i ~/Vidéos/BigBuckBunny/bbb_sunflower_native_60fps_normal.mp4 -t 30 -r 25 -c:v libx265 -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0 -movflags +faststart -map 0:0 -map 0:1 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/bbb_sunflower_native_60fps_normal_EN_x265_25fps_12500_cpu.mkv
### GPU Based encoding (HEVC)
_** Desktop: GPU HEVC works only for graphics cards Geforce GTX 950 series or higher graphics cards (GTX 950, GTX 960, GTX 970, GTX 980, GTX Titan X) **_
_** Laptop: GTX 965M, 970M, 980M or higher graphics cards **_

	time ./ffmpeg -y -i ~/Vidéos/BigBuckBunny/bbb_sunflower_native_60fps_normal.mp4 -t 30 -r 25 -c:v hevc_nvenc -vf "scale=1920:trunc(ow/a/2)*2" -pix_fmt yuv420p -b:v 6250k -maxrate:v 12500k -bufsize 12500k -x264-params threads=0:level=51:aq-mode=1:intra-refresh=0:b-pyramid=0 -movflags +faststart -map 0:0 -map 0:1 -metadata:s:a:0 language=eng -c:a ac3 -b:a 384k -ar 48000 -ac 2 ~/Vidéos/bbb_sunflower_native_60fps_normal_EN_x265_25fps_12500_gpu.mkv
***
### CPU Utilization
* `top`
* `vmstat -w -n 1`

### GPU Utilization
* `nvidia-smi`
* `nvidia-smi dmon -i 0`
***
### CUDA Tools binaries
1. `cuda-install-samples-8.0.sh <dir>`
2. `cd NVIDIA_CUDA-8.0_Samples`
3. `make`
4. `cd bin`
5. `./deviceQuery`
6. `./bandwidthTest`

Finished :)
