---
layout: post
title: "Analyzing Binary Data in Couchbase"
description: How to build Couchbase Views on binary data
gplus: true
---

Today I've found one question on StackOverflow about [how to access
binary data in views][1]. My answer was, yes, it is possible to
access non-json documents, but they are represented in Base64 encoding
and embedded into JSON object. But to me, the next and more
interesting question was how to inspect binary data in views to
extract useful info, needed to build secondary index. In this post I
will explain how to do it using simple example: generating MIME type for
image from its magic number.

Lets assume, you are writing the service like gravatar, and using
Couchbase to as distributed high-performance storage to keep images.

With this ruby script you can pre-populate your Couchbase bucket for
this exercise:

    require 'couchbase'

    path = ARGV[0] || "."
    conn = Couchbase.connect(:bucket => "avatars", :default_format => :plain)
    Dir[File.join(path, "*")].each do |img|
      conn.set(img, File.read(img))
      puts "#{img} saved"
    end

It will just upload all files from current directory to the bucket
`"avatars"`.

When Couchbase Server detects that the document doesn't look like
JSON, it will keep it as is, and later expose it in Base64 form when
someone will try to inspect its value. Our map function will be
simple: pick few bytes from header, and lookup in magic database (you
can find these numbers in format specs). In this example it will be
enough to pick first eight bytes, because our database knows only
about three image formats: JPEG, PNG and GIF.

    function (doc, meta) {
      if (meta.type == "base64") {
        var cmp = function(ref, val) {
          for (var i = 0, l = ref.length; i < l; ++i) {
            if (ref[i] != val[i]) {
              return false;
            }
          }
          return true;
        };

        var database = [
          {type: "image/png", magic: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]},
          {type: "image/jpeg", magic: [0xff, 0xd8]},
          {type: "image/gif", magic: [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]},
          {type: "image/gif", magic: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]},
        ]
        var binary = decodeBase64(doc);
        var header = binary.slice(0, 8);
        for (var i = 0, l = database.length; i < l; ++i) {
          if (cmp(database[i].magic, header)) {
            emit(meta.id, database[i].type);
            return;
          }
        }
        emit(meta.id, "application/octect-stream");
      }
    }

Pay attention to following aspects in this snippet. First, the
document type for binary non-json document will be `"base64"`.
Second, you don't allowed to define your functions on the top-level of
the javascript code, there should be only one anonymous function (map
function), but you can define them anywhere else, like I've done it if
the document considered in Base64 encoding. And the latest one, and
probably most important here, `decodeBase64` function. This is
built-in function, along with `emit`, `sum` and `dateToArray`. It
accepts a string in Base64 format and returns array of bytes.

Now lets save our view as `_design/binary/_view/mime` and execute with
following ruby code:

    require 'couchbase'

    conn = Couchbase.connect(:bucket => "avatars")
    conn.design_docs["binary"].mime(:stale => false).each do |row|
      printf "%s => %s\n", row.id, row.value
    end

On my bucket, the output looks like this:

    $ ruby execute.rb
    ./execute.rb => application/octect-stream
    ./glider.gif => image/gif
    ./glider.jpg => image/jpeg
    ./glider.png => image/png
    ./populate.rb => application/octect-stream

[1]: http://stackoverflow.com/questions/17104465/does-the-couchbase-rest-api-support-non-json-data-binary-data
