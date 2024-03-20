<h3 align="center"><img src="./test/render-for.demo.gif" alt="demo" height="400px"></h3>
<p align="center"><code>thu.sh</code> renders preview images to the terminal; ~1000 LOC bash</p>
<p align="center">
<a href="https://github.com/iambumblehead/thu.sh/workflows"><img src="https://github.com/iambumblehead/thu.sh/workflows/test/badge.svg"></a>
<a href="./LICENSE.md"><img src="https://img.shields.io/badge/license-GPLv3-blue.svg"></a>
<a href="https://github.com/iambumblehead/thu.sh/releases"><img src="https://img.shields.io/github/release/iambumblehead/thu.sh.svg"></a>
</p>

> [!WARNING]
> This project has no major releases and sources will change suddenly any time. Few unit tests at this time.

**thu.sh renders images for various file types to the terminal.** It renders images from audio, font, video, pdf, epub, svg and other files --supporting both kitty and sixel formats. It detects available commands from the system for a small dependency tree,
 * `magick` sixel or `kitten icat` display,
 * `mutool`, `pdftoppm` or `magick` pdf,
 * `ffmpeg` video audio,
 * `magick` font,
 * `unzip` epub,
 * `exiftool` or `identify` file type


```bash
thu.sh /path/to/image.png
thu.sh /path/to/font.ttf
thu.sh /path/to/video.mp4

# preview image will be scaled to fit optional width and height params
thu.sh /path/to/music.flac 800 400
thu.sh /path/to/image.svg 600 600
thu.sh /path/to/book.pdf
thu.sh /path/to/book.epub
```

<dl>
  <dt>Which terminal emulators will render images?</dt>
  <dd>`iTerm2`, `kitty` and `foot` can render images with this script. Sixel support for other terminals is listed here https://www.arewesixelyet.com/</dd>
  <dd>`xterm` can be configured, see https://github.com/iambumblehead/thu.sh/wiki#with-xterm</dd>
  <dt>Anything else?</dt>
  <dd>Suggestions and improvements are welcome and appreciated. `thu.sh` may feel "slow" as it presently does not yet cache or reuse preview images it generates.</dd>
</dl>


----------------------------------------------

**Add sixel image preview** to the [vifm file manager.][3] Instructions [at the wiki.][3]

<div align="left">
<img src="./test/render-for-vifm.gif" alt="vifm" height="240px"> <img src="./test/render-for-miller.png" alt="vifm" height="240px">
</div>



[0]: https://img.shields.io/badge/license-ISC-blue.svg
[1]: ./LICENSE
[2]: https://github.com/vifm/vifm
[3]: https://github.com/iambumblehead/thu.sh/wiki
