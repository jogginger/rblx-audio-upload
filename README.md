# rblx-audio-upload

Very simple tool to upload a folder of sound files to roblox (currently not based on the Roblox cloud asset api)

## Prerequisites

[rokit](https://github.com/rojo-rbx/rokit)
[ffmpeg](https://ffmpeg.org/) (Optional, to compute estimated audio lengths)

## Setup

Run `rokit install`

## Usage

- Move audio files into a folder (files in that folder will be uploaded)
- Run the program

```bash
lune run Upload.luau
```

## Arguments
`--group, -g` The group ID to upload to

`--source, -s` The path of the folder you want to upload audio files from ("./sounds" by default)

`--verbose, -v` Enables logging
