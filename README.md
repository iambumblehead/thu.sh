<h3 align="center"><img src="./test/render-for.demo.gif" alt="demo" height="400px"></h3>
<p align="center"><code>render-thumb-for.sh</code> renders preview images to the terminal; ~500 LOC bash</p>
<p align="center">
<a href="https://github.com/iambumblehead/render-thumb-for.sh/workflows"><img src="https://github.com/iambumblehead/render-thumb-for.sh/workflows/shellcheck/badge.svg"></a>
<a href="./LICENSE.md"><img src="https://img.shields.io/badge/license-ISC-blue.svg"></a>
<a href="https://github.com/iambumblehead/render-thumb-for.sh/releases"><img src="https://img.shields.io/github/release/iambumblehead/render-thumb-for.sh.svg"></a>
</p>

`render-thumb-for.sh` renders sixel or kitty images of various file type to the terminal, using ffmpeg and imagemagick.
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

<dl>
  <dt>Which terminal emulators are capabale of rendering images?</dt>
  <dd>A great terminal emulator on GNU/Linux is "foot". Support for other terminals is listed here https://www.arewesixelyet.com/</dd>
  <dt>What dependencies are needed?</dt>
  <dd>`imagemagick`, `ffmpeg` (video, audio), `unzip` (epub), `pdftoppm` or `mutool` (pdf) and `exiftool` is optionally used when the command is available, else system `identity` command is used.</dd>
  <dt>What is the benefit of `render-thumb-for.sh` compared to `lsix` or `vifmimg`?</dt>
  <dd>`lsix` does not by itself provide out-of-box behaviour needed for a filemanager; it does not render video, audio or epub and will not manage a file cache. It does render images to kitty terminal.</dd>
  <dd>`vifmimg` requires a bigger dependency tree including a python runtime and `epub-thumbnailer` with attendant xorg-specific utilities</dd>
  <dd>`render-thumb-for.sh` provides more file-manager-functionality than `lsix` with a smaller dependency tree and simpler interface than `vifmimg`. It will also render images to kitty terminal emulator.</dd>
  <dt>Anything else?</dt>
  <dd>Suggestions and improvements are welcome and appreciated. `render-thumb-for.sh` is new and will have bugs. `render-thumb-for.sh` may feel "slow" as it presently does not yet cache or reuse preview images it generates.</dd>
</dl>


----------------------------------------------

**Add sixel image preview** to the [vifm file manager.][3] Instructions [at the wiki.][3]

<div align="left">
<img src="./test/render-for-vifm.gif" alt="vifm" height="240px"> <img src="./test/render-for-miller.png" alt="vifm" height="240px">
</div>



[0]: https://img.shields.io/badge/license-ISC-blue.svg
[1]: ./LICENSE
[2]: https://github.com/vifm/vifm
[3]: https://github.com/iambumblehead/render-thumb-for.sh/wiki
