#!/usr/bin/env ruby

require 'exif'
require 'fileutils'
require 'pathname'
require 'gpx_utils'
require 'exif_geo_tag'
require 'time'
require 'English'

class GpxUtils::TrackImporter
  THRESHOLD = 5 * 60

  def find_by_time(time)
    @coords
      .select { |c| (c[:time].localtime - time.localtime).abs < THRESHOLD }
      .sort { |a, b| (a[:time].localtime - time.localtime).abs <=> (b[:time].localtime - time.localtime).abs }
      .first
  end

  def write_tag(path, timestamp)
    point = find_by_time(timestamp)
    return unless point
    tags = {
      _latitude: point[:lat],
      _longitude: point[:lon],
      _altitude: point[:alt],
      _timestamp: point[:time].utc
    }
    puts "geotag #{path} <- #{tags}"
    ExifGeoTag.write_tag(path, tags)
  end

  # Only import valid coords
  def self.coord_valid?(lat, lon, _elevation, time)
    return true if lat && lon && time
    false
  end

  def self.proc_time(ts)
    Time.parse(ts)
  end
end

def relocate(from, to, tmp = nil, timestamp = nil)
  FileUtils.mkdir_p(File.dirname(to))
  if tmp
    FileUtils.mkdir_p(File.dirname(tmp))
    puts "cp #{from} #{tmp}"
    FileUtils.cp(from, tmp)
    FileUtils.chmod(0o644, tmp)
    FileUtils.touch(tmp, mtime: timestamp) if timestamp
  end
  puts "mv #{from} #{to}"
  FileUtils.mv(from, to)
  FileUtils.chmod(0o644, to)
  FileUtils.touch(to, mtime: timestamp) if timestamp
end

gpx = GpxUtils::TrackImporter.new
FileUtils.mkdir_p('gpx')
Dir['src/*.[Gg][Pp][Xx]'].each do |path|
  gpx.add_file(path)
  base = File.basename(path)
  puts "mv #{path} gpx/"
  FileUtils.mv(path, 'gpx/')
end

Dir['src/**/*.[Tt][Hh][Mm]'].each do |path|
  puts "rm #{path}"
  FileUtils.rm_rf(path)
end

Dir['src/**/.*.[Jj][Pp][Gg]'].each do |path|
  puts "rm #{path}"
  FileUtils.rm_rf(path)
end

Dir['src/**/*.[Jj][Pp][Gg]'].each do |path|
  data = Exif::Data.new(path)
  date = data.date_time.strftime('%Y-%m-%d')
  base = File.basename(path).gsub(/\.jpg$/i, '')
  gpx.write_tag(path, data.date_time)
  relocate(path, "out/#{date}/#{base}.jpg", "tmp/#{base}.jpg", data.date_time)
end

Dir['src/**/*.[Aa][Rr][Ww]'].each do |path|
  data = File.stat(path)
  date = data.mtime.strftime('%Y-%m-%d')
  base = File.basename(path).gsub(/\.arw$/i, '')
  relocate(path, "raw/#{date}/#{base}.arw")
end

Dir['src/**/*.[Mm][Pp]4'].each do |path|
  data = `mediainfo --Output="Video;%Encoded_Date%" #{path}`.strip
  encoded_date = DateTime.parse(data).to_time
  date = encoded_date.strftime('%Y-%m-%d')
  base = File.basename(path).gsub(/\.mp4$/i, '')
  relocate(path, "out/#{date}/#{base}.mp4", "tmp/#{base}.mp4", encoded_date)
end

Dir['src/**/*.[Aa][Vv][Ii]'].each do |path|
  data = File.stat(path)
  date = data.mtime.strftime('%Y-%m-%d')
  timestamp = data.mtime.strftime('%Y-%m-%d %H:%M:%S')
  mp4_path = path.gsub(/\.avi$/i, '.mp4')
  cmd = "ffmpeg -y -i #{path} -c copy -map 0 -metadata creation_time='#{timestamp}' #{mp4_path} 2>&1"
  puts cmd
  output = `#{cmd}`
  if $CHILD_STATUS.success?
    puts "rm -rf #{path}"
    FileUtils.rm_rf(path)
    base = File.basename(mp4_path).gsub(/\.mp4$/i, '')
    relocate(mp4_path, "out/#{date}/#{base}.mp4", "tmp/#{base}.mp4", data.mtime)
  else
    abort(output)
  end
end

Dir['src/*'].each do |dir|
  path = Pathname.new(dir)
  if path.directory? && path.children.empty?
    puts "rmdir #{path}"
    FileUtils.rmdir(path)
  end
end
