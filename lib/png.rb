RMAGICK_BYPASS_VERSION_TEST = true
require "RMagick"
puts "xxx"

def show_info(fname)
  img = Magick::Image::read(fname).first
  fmt = img.format
  w,h = img.columns, img.rows
  dep = img.depth
  nc  = img.number_colors
  nb  = img.filesize
  xr  = img.x_resolution
  yr  = img.y_resolution
  res = Magick::PixelsPerInchResolution ? "inch" : "cm"
  puts <<-EOF
  File:       #{fname}
  Format:     #{fmt}
  Dimensions: #{w}x#{h} pixels
  Colors:     #{nc}
  Image size: #{nb} bytes
  Resolution: #{xr}/#{yr} pixels per #{res}
  EOF
  puts

  File.open("test.txt", "w") do |f|
    img.each_pixel do |p, col, row|
      hue = p.to_hsla[0]
      if hue!=0 && hue<100 then
        f.puts "hue: #{p.to_hsla[0]}, rgb: #{p.to_color},col: #{col}, row: #{row}"
      end
    end
  end


end

show_info("b.tga")