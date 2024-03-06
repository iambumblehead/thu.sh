<h3 align="center"><img src="./test/render-for.demo.gif" alt="demo" height="400px"></h3>
<p align="center"><code>render-for.sh</code> renders preview images to the terminal; ~500 LOC bash</p>
<p align="center">
<a href="https://github.com/iambumblehead/render-thumb-for.sh/workflows"><img src="https://github.com/iambumblehead/render-thumb-for.sh/workflows/shellcheck/badge.svg"></a>
<a href="./LICENSE.md"><img src="https://img.shields.io/badge/license-ISC-blue.svg"></a>
<a href="https://github.com/iambumblehead/render-thumb-for.sh/releases"><img src="https://img.shields.io/github/release/iambumblehead/render-thumb-for.sh.svg"></a>
</p>

`render-for.sh` renders sixel images of various file type to the terminal, using ffmpeg and imagemagick.
```bash
# image, font, video, music, pdf and epub files
render-for.sh /path/to/image.png
render-for.sh /path/to/font.ttf
render-for.sh /path/to/video.mp4

# preview image will be scaled to fit optional width and height params
render-for.sh /path/to/music.flac 800 400
render-for.sh /path/to/image.svg 600 600
render-for.sh /path/to/book.pdf
render-for.sh /path/to/book.epub
```

_**Suggestions and improvements are welcome.** `render-for.sh` is new and may have bugs; please report them. `render-for.sh` may feel "slow" because it does not yet cache or reuse preview images it generates_


[0]: https://img.shields.io/badge/license-ISC-blue.svg
[1]: ./LICENSE
