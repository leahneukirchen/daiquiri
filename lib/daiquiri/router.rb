module Daiquiri
  class Router
    def initialize(map)
      @routes = map.map { |path, app| [app, *path2regexp(path)] }
    end

    def path2regexp(path)
      args = []

      regex = Regexp.new('\A' + path.gsub(/\{(\w+)(?::(\w+))?\}/) {
                           args << $1
                           case $2
                           when nil, 'seg': '([^/]+?)'  # default: anything but /
                           when 'ext':      '\.(\w+)'
                           when 'all':      '(.*?)'
                           when 'num':      '(-?\d+)'
                           else
                             raise ArgumentError, "invalid qualifier in {#$1:#$2}"
                           end
                         } + '\z')

      [regex, *args]
    end

    def call(env)
      path = env["PATH_INFO"].to_s
      path = "/"  if env.empty?

      @routes.each { |app, rx, *args|
        if path =~ rx
          env["daiquiri.routing_args"] = Hash[*args.zip($~.captures).flatten]
          return app.call(env)
        end
      }
      return [404, {"Content-Type" => "text/html", "Content-Length" => 0}, []]
    end
  end
end
