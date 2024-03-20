# changelog

 * 0.0.8 _Mar.16.2024_
   * added [less trivial tests](https://github.com/iambumblehead/render-thumb-for.sh/pull/33)
   * support returning queried data [using -p arg](https://github.com/iambumblehead/render-thumb-for.sh/pull/34)
   * support [both imagemagick 7 an 8](https://github.com/iambumblehead/render-thumb-for.sh/pull/36)
   * use cell size rather than window to [construct view area size](https://github.com/iambumblehead/render-thumb-for.sh/pull/37)
 * 0.0.7 _Mar.14.2024_
   * improve [support for xterm](https://github.com/iambumblehead/render-thumb-for.sh/pull/25)
   * added [support for cell units](https://github.com/iambumblehead/render-thumb-for.sh/pull/26)
   * migrate [from convert command to magick](https://github.com/iambumblehead/render-thumb-for.sh/pull/26), per [advice here](https://github.com/ImageMagick/ImageMagick/discussions/7168) (maybe both 'convert' and 'magick' should be supported?)
   * support [pdf images with imagemagick](https://github.com/iambumblehead/render-thumb-for.sh/pull/26)
   * added [support for zoom param, eg -z 3](https://github.com/iambumblehead/render-thumb-for.sh/pull/26), used for foot <= 1.16.2, see [link](https://codeberg.org/dnkl/foot/issues/1643)
   * added bash_unit [unit test and pipeline](https://github.com/iambumblehead/render-thumb-for.sh/pull/30)
   * added logic to [determine if stdout available,](https://github.com/iambumblehead/render-thumb-for.sh/pull/31) eg to detect if escape queries need to be send to tty rather than stdout
 * 0.0.6 _Mar.07.2024_
   * added sixel and kitty [differentiation to README](https://github.com/iambumblehead/render-thumb-for.sh/pull/16)
   * added [sixel detection](https://github.com/iambumblehead/render-thumb-for.sh/pull/17)
   * added [getopts support](https://github.com/iambumblehead/render-thumb-for.sh/pull/23)
   * improve [kitty image support](https://github.com/iambumblehead/render-thumb-for.sh/pull/24)
 * 0.0.5 _Mar.07.2024_
   * added support iterm2 mac [#14](https://github.com/iambumblehead/render-thumb-for.sh/pull/14)
   * added support kitty mac [#15](https://github.com/iambumblehead/render-thumb-for.sh/pull/15)
 * 0.0.4 _Mar.06.2024_
   * added pdf support for optional mutool command [#13](https://github.com/iambumblehead/render-thumb-for.sh/pull/13)
 * 0.0.3 _Mar.06.2024_
   * added pdf thumb generation [#4](https://github.com/iambumblehead/render-thumb-for.sh/pull/4)
   * added font thumb generation [#5](https://github.com/iambumblehead/render-thumb-for.sh/pull/5)
   * added epub thumb generation [#7](https://github.com/iambumblehead/render-thumb-for.sh/pull/7)
   * added function to return simplified filetype for file [#6](https://github.com/iambumblehead/render-thumb-for.sh/pull/6)
   * use temp directory as generated image destination [#8](https://github.com/iambumblehead/render-thumb-for.sh/pull/8)
   * remove commented-out example calls [#9](https://github.com/iambumblehead/render-thumb-for.sh/pull/9)
   * added demo gif [#10](https://github.com/iambumblehead/render-thumb-for.sh/pull/10)
   * smoke-tested the release pipeline and released v0.0.1
   * begin integrating with vifm and [update the README](https://github.com/iambumblehead/render-thumb-for.sh/pull/11)
   * added vifm [gif to README](https://github.com/iambumblehead/render-thumb-for.sh/pull/11)
   * smoke-tested [usage of exiftool](https://github.com/iambumblehead/render-thumb-for.sh/pull/12)
 * 0.0.2 _Mar.02.2024_
   * added video thumb generation [#2](https://github.com/iambumblehead/render-thumb-for.sh/pull/2)
   * added audio thumb generation [#3](https://github.com/iambumblehead/render-thumb-for.sh/pull/3)
   * added functions return video length, dimensions using ffmpeg
 * 0.0.1 _Feb.20.2024_
   * [initial setup.](https://github.com/iambumblehead/render-thumb-for.sh/pull/1)
   * added initial shell script, README.md, CHANGELOG.md and LICENSE
   * added ci-job shellcheck
   * added behaviour to render images, differentiating svg
   * added .gitattributes to one day filter demo images included at git release
   * experimented w/ libsixel `img2sixel` and imagemagick `covert`, decided on `convert`
   * investigated thumbnail generation for other file types
