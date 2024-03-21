# thu.sh! 🚀

<img align="right" src="./test/render-for.demo.gif" alt="demo" height="280">

`thu.sh` renders preview images to the terminal; ~1000 LOC bash

[![test][1]][0] [![license][3]][2] [![release][5]][4] [![][7]][6]

**thu.sh renders images from audio, font, video, pdf, epub, svg** and other files --supporting both kitty and sixel formats. It detects available commands from the system for a small dependency tree,
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


[0]: https://github.com/iambumblehead/thu.sh/workflows "test link"
[1]: https://github.com/iambumblehead/thu.sh/workflows/test/badge.svg "test badge"
[2]: ./LICENSE.md "license link"
[3]: https://img.shields.io/badge/license-GPLv3-blue.svg "license badge"
[4]: https://github.com/iambumblehead/thu.sh/releases "release link"
[5]: https://img.shields.io/github/release/iambumblehead/thu.sh.svg "release badge"
[6]: ./thu.sh "thu.sh"
[7]: https://img.badgesize.io/iambumblehead/thu.sh/main/thu.sh.svg?compression=gzip "size badge"

----------------------------------------------

**Add sixel image preview** to [vifm file manager.][10] Instructions [at the wiki.][11]

<div align="left">
<img src="./test/render-for-vifm.gif" alt="vifm" height="240px"> <img src="./test/render-for-miller.png" alt="vifm" height="240px">
</div>


[10]: https://github.com/vifm/vifm
[11]: https://github.com/iambumblehead/thu.sh/wiki
