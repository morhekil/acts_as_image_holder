#
# This class handles the images proccessing
#
# Copyright (C) by Nikolay V. Nemshilov aka St.
#
class ActsAsImageHolder::ImageProc
  class << self
    #
    # prepares the data of the field, perfomes resizing and type changes
    #
    def prepare_data(file, field)
      blob = resize(file, field.size, field.type, field.quality)
      blob = watermark_blob(blob, field.watermark) if field.watermark
      blob
    end
    
    # gets the image type
    def get_type(file)
      image_from(file).format.downcase.to_sym
    end
    
    # resizes the given file
    def resize(file, size, format=nil, quality=nil)
      image = image_from(file)
      
      image.change_geometry!(size){ |cols, rows, img|
        img.resize!(cols, rows)
      } if size and size != ""
      
      image.format = format.to_s if format
      
      image.to_blob { self.quality = quality if quality }
    end
    
    # converts the given source to a blob-string
    def to_blob(file)
      image_from(file).to_blob
    end
    
    # watermarks the given image
    # accepts a source or an image instance
    def watermark(image, options)
      image = image_from(image) unless image.is_a? Magick::Image
      ActsAsImageHolder::ImageProc::Watermarker.process(image, options)
    end
    
    # same as the 'watermark' method but accepts and returns a blob string
    def watermark_blob(blob, options)
      ActsAsImageHolder::ImageProc::Watermarker.process(Magick::Image.from_blob(blob).first, options).to_blob
    end
    
  private
    # converts the source into an image object
    def image_from(src)
      if src.is_a?(ActionController::UploadedStringIO) or 
          src.is_a?(ActionController::UploadedTempfile) or
          src.is_a?(File)
        src.rewind
        data = src.read
      else
        data = src
      end
      
      Magick::Image.from_blob(data).first
    end
    
    # parses out the size options
    # returns a list like [width, height, resize-type]
    def parse_size_options(str)
      if match = str.match(/(\d*)(x*)(\d*)(\!|>)/)
        [match[1].to_i, match[3].to_i,
         match[4]==">" ? :zoom : (match[4]=="!" ? :exact : :usual)]
      else
        [0, 0, :usual]
      end
    end
  end
end
