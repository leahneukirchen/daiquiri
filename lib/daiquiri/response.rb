require 'ostruct'

module Daiquiri
  class Response < Rack::Response
    def initialize
      super

      @headers = {}
      @data = OpenStruct.new

      @buffers = [[]]
    end

    attr_accessor :req
    attr_accessor :data

    def content_type=(ct)
      @headers['Content-Type'] = ct
    end

    def etag=(etag)
      @headers['ETag'] = etag
    end

    def last_modified=(time)
      @headers['Last-Modified'] = time.httpdate
    end

    attr_accessor :message
    attr_accessor :status

    def abort
      fail
    end

    def encode(str)
      write Rack::Utils.escape_html(str)
    end

    def pop
      @buffers.pop.join
    end

    def push
      @buffers << []
    end

    def redirect(href)
      self.status = 302
      self['Location'] = href
      reset_buffer
      write %r{<a href="#{href}">#{href}</a>\n}
      href
    end

    def redirect_back
      redirect req.referer
    end

    def reset
      @buffers.last.clear
    end

    def reset_buffer
      @buffers = [[]]
    end

    alias _write write
    def write(str)
      p @buffers
      @buffers.last << str
      p @buffers
    end

    def finish
      p @buffers
      while @buffers.size > 1
        write pop
      end
      _write pop
      super
    end

    def empty?
      @buffers == [[]]
    end
  end
end
