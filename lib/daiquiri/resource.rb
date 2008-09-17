require 'daiquiri/htemplate'

module Daiquiri
  module Resourceful
    def call(env)
      action = (env["daiquiri.routing_args"] || {})["action"]
      id     = (env["daiquiri.routing_args"] || {})["id"]
      method = action || case env["REQUEST_METHOD"]
                         when "GET"
                           id ? "show" : "index"
                         when "POST"
                           "create"
                         when "PUT"
                           "update"
                         when "DELETE"
                           "destroy"
                         else
                           env["REQUEST_METHOD"].downcase
                         end

      Thread.current[:daiquiri_req] = req = Rack::Request.new(env)
      Thread.current[:daiquiri_res] = res = Response.new
      res.req = req

      __send__(method)

      if res.empty?
        render_template(self.class.name.downcase.gsub('::', '-') +
                        "-#{method}.ht", res.data)
      end

      res.finish
    end

    def req
      Thread.current[:daiquiri_req]
    end

    def res
      Thread.current[:daiquiri_res]
    end

    def render_template(file, data)
      res.write HTemplate.new(File.read(file), file).expand(data)   # XXX cache
    end
  end

  class Resource
    include Resourceful
  end
end
