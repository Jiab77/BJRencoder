# BJRencoder

Open source encoding software based on FFMpeg

## Installation

You just need [ffmpeg](https://github.com/FFmpeg/FFmpeg) to be installed on your system.

## Content extraction

Actually, I'm building a tiny script that extract file content track by track. It's still in alpha state but completely functionnal.

> You may found some parsing bug depending on your input file. If that's the case, please fill an issue and I'll try to do my best to fix it.

The script is named `ffextract.bat` for the moment.

### Graphical

Just drag and drop your file on the script

### Command line

```batch
> ffextract.bat [your-file-to-process.ext]
```

## Read the file content

I've created a small script (*it miss some comments...*) `ffscan.bat` to this purpose. I've used this code to create the extraction script.

### Graphical

Just drag and drop your file on the script

### Command line

```batch
> ffscan.bat [your-file-to-process.ext]
```
