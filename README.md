<h3 align="center"><img src="./test/render-for.demo.gif" alt="demo" height="400px"></h3>
<p align="center"><code>render-thumb-for.sh</code> renders preview images to the terminal; ~500 LOC bash</p>
<p align="center">
<a href="https://github.com/iambumblehead/render-thumb-for.sh/workflows"><img src="https://github.com/iambumblehead/render-thumb-for.sh/workflows/shellcheck/badge.svg"></a>
<a href="./LICENSE.md"><img src="https://img.shields.io/badge/license-ISC-blue.svg"></a>
<a href="https://github.com/iambumblehead/render-thumb-for.sh/releases"><img src="https://img.shields.io/github/release/iambumblehead/render-thumb-for.sh.svg"></a>
</p>

`render-thumb-for.sh` renders sixel images of various file type to the terminal, using ffmpeg and imagemagick.
```bash
# image, font, video, music, pdf and epub files
render-thumb-for.sh /path/to/image.png
render-thumb-for.sh /path/to/font.ttf
render-thumb-for.sh /path/to/video.mp4

# preview image will be scaled to fit optional width and height params
render-thumb-for.sh /path/to/music.flac 800 400
render-thumb-for.sh /path/to/image.svg 600 600
render-thumb-for.sh /path/to/book.pdf
render-thumb-for.sh /path/to/book.epub
```

----------------------------------------------

**Add sixel image preview** to the [vifm file manager.][3] 

<div align="center"><img src="./test/render-for-vifm.gif" alt="vifm" height="240px"></div>

First, download and extract the latest `render-thumb-for.sh` to vifm's xdg _~/.config/vifm/scripts/_. A one-liner command can be used [from the wiki][3]

Then update vifmrc to use `render-thumb-for.sh` changing width and height multipliers `30` and `64` below to suite your terminal and layout. Remove file extensions used by this fileviewer from all other fileviewer directives.
_~/.config/vifm/vifmrc_
``` ini
fileviewer {*.bmp,*.jpg,*.jpeg,*.png,*.gif,*.xpm,*.svg,*.pdf,*.epub,
           \*.ttf,*.otf,*.woff,*.wav,*.mp3,*.flac,*.m4a,*.wma,*.ape,
           \*.ac3,*.og[agx],*.spx,*.opus,*.aac,*.mpga,*.avi,*.mp4,
           \*.wmv,*.dat,*.3gp,*.ogv,*.mkv,*.mpg,*.mpeg,*.vob,
           \*.fl[icv],*.m2v,*.mov,*.webm,*.ts,*.mts,*.m4v,*.r[am],
           \*.qt,*.divx,*.as[fx],*.unknown_video},
         \ render-thumb-for.sh %c %pw %ph 30 64 %pd
```

_**Suggestions and improvements are welcome and appreciated.** `render-thumb-for.sh` is new and will have bugs. `render-thumb-for.sh` may feel "slow" presently because it does not yet cache or reuse preview images it generates._



[0]: https://img.shields.io/badge/license-ISC-blue.svg
[1]: ./LICENSE
[2]: https://github.com/vifm/vifm
[3]: https://github.com/iambumblehead/render-thumb-for.sh/wiki
