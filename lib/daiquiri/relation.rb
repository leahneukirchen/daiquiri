module Daiquiri
  class Relation
    def call(env)
      app = fetch(env["daiquiri.routing_args"] || {})
      if app
        app.call(env)
      else
        return not_found(env)
      end
    end

    def not_found(env)
      [404, {"Content-Type" => "text/html", "Content-Length" => 0}, []]
    end

    def fetch(args)
      raise NotImplementedError, "tried to fetch abstract resource"
    end
  end

  module Persistable
    module ClassMethods

      def attr_converted(field, setter=nil, getter=nil)
        ivar = "@#{field}".to_sym
        setter and define_method("#{field}=") { |value|
          instance_variable_set(ivar, setter[value])
        }
        getter and define_method(field) {
          getter[instance_variable_get(ivar)]
        }
        field
      end

      def from_hash(hash)
        obj = allocate
        hash.each { |key, value|
          obj.send("#{key}=", value)
        }
        obj
      end

    end

    def self.included(klass)
      klass.class_eval {
        extend ClassMethods
        attr_accessor :_id
      }
    end

    def to_json(state=nil)
      hash = {"_class" => self.class.name}
      self.class.instance_methods.grep(/\A\w+=\z/).find_all { |m|
        hash[m[0...-1]] = __send__(m[0...-1])
      }
      hash.to_json
    end
  end

  module SingletonRelation
    def fetch(args)
      self
    end
  end
end
