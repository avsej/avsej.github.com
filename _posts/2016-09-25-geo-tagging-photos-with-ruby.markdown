---
layout: post
title: "Geo Tagging Photos with Ruby"
description: How to inject EXIF tags with geoposition with ruby
---

Recenty I started to use my Sony a5000 more often mostly because my phone camera is pretty bad, and I don't want to
blame myself later. The camera is pretty good, but lack one important feature for me: it does not record geo information
into the photos like all of the phones do.

After quick googling, I settled with using my phone as external GPS tracker and record tracks into GPX format. Cheep and
efficient when you have external battery :). But the software to inject the tags was open question. As I don't use any
photo organizer except google photos (which is more like a storage rather than organizer), using any desktop solution
looked like overkill. More over they usually do not support Linux and/or FreeBSD. So I came to scripting solution.

In ruby land, there are few EXIF libraries, with different features and capabilities. I will just enumerate some of them:

* [exif][gem-exif]: I really like this bindings to [libexif][libexif], but it does not support writing tags (as for
  autumn 2016), so it does not qualify my requirements.

* [exiftool][gem-exiftool]: also does not write tags, but also `exiftool` does not accessible in FreeBSD packages.

* [gpx2exif][gem-gpx2exif]: this library supports writing, and in particular designed for setting geo information, but
  it still uses `exiftool` and also write lots of [extra garbage][extra-garbage] into tags.

Eventually I set to write trivial ruby wrapper around [libexif][libexif] and it resulted
in [exif_geo_tag][gem-exif_geo_tag] library. It handles only tags defined in "GPS Attribute Information" section
of [Exif 2.2 specification][exif22] and does it efficiently. In addition to writing tags directly, it allows to specify
"virtual" tags, which handle type conversion (full list of tags in [README][readme]). For example instead of specifying
coordinates in form of degrees, minutes and seconds:

    ExifGeoTag.write_tag('/tmp/photo.jpg', longitude: [18, 46, 20.284],
                                           latitude: [42, 25, 32.372])

you can just use fields with underscore with float values and it will perform appropriate conversion (which is useful
when working with GPX data):

    ExifGeoTag.write_tag('/tmp/photo.jpg', _longitude: 18.772301111111112,
                                           _latitude: 42.42565888888889)


In my script I also use to load Navitel GPX files with [small patch][patch-gpx_utils] I hope eventually get into the
upstream. If you are curious, my full script for tagging and sorting out photos before uploading to Google Photos is
here: [classify.rb][script-classify.rb].

[gem-exif]: https://rubygems.org/gems/exif
[gem-exiftool]: https://rubygems.org/gems/exiftool
[gem-gpx2exif]: https://rubygems.org/gems/gpx2exif
[libexif]: http://libexif.sourceforge.net/
[extra-garbage]: https://github.com/akwiatkowski/gpx2exif/blob/16795324f19029c4d4cf6be9bebe8026a2ec6bfb/lib/geotagger/exif_editor.rb#L46]
[gem-exif_geo_tag]: https://rubygems.org/gems/exif_geo_tag
[exif22]: http://exif.org/Exif2-2.PDF
[gem-gpx_utils]: https://rubygems.org/gems/gpx_utils
[readme]: https://github.com/avsej/exif_geo_tag#readme
[patch-gpx_utils]: https://github.com/akwiatkowski/gpx_utils/pull/1/files
[script-classify.rb]: /classify.rb
