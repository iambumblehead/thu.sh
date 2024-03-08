<h3 align="center"><img src="./test/render-for.demo.gif" alt="demo" height="400px"></h3>
<p align="center"><code>render-thumb-for.sh</code> renders preview images to the terminal; ~500 LOC bash</p>
<p align="center">
<a href="https://github.com/iambumblehead/render-thumb-for.sh/workflows"><img src="https://github.com/iambumblehead/render-thumb-for.sh/workflows/shellcheck/badge.svg"></a>
<a href="./LICENSE.md"><img src="https://img.shields.io/badge/license-ISC-blue.svg"></a>
<a href="https://github.com/iambumblehead/render-thumb-for.sh/releases"><img src="https://img.shields.io/github/release/iambumblehead/render-thumb-for.sh.svg"></a>
</p>

`render-thumb-for.sh` renders images for various file types to the terminal. It renders images from audio, font, video, pdf, epub, svg and other files --supporting both kitty and sixel formats. It detects available commands from the system and has a small dependency tree,
 * `imagemagick` (sixel) or `kitten icat` (kitty),
 * `ffmpeg` (video, audio),
 * `unzip` (epub),
 * `pdftoppm` or `mutool` (pdf),
 * `exiftool` or `identify` (probe file properties).


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
  <dd>A great terminal emulator on GNU/Linux is `foot` and it supports sixel images. Sixel support for other terminals is listed here https://www.arewesixelyet.com/</dd>
  <dd>`iTerm2` and `kitty` also render images with this script</dd>
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
