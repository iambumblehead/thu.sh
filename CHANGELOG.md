# changelog

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
