require 'json'
require 'fileutils'

module Daiquiri
  class JSONFileStore < Relation
    def initialize(dir)
      @dir = File.expand_path(dir)
      FileUtils.mkdir_p(dir)
    end

    def fetch(args)
      return nil  unless args["id"]
      json = File.read(File.join(@dir, args["id"] + ".json"))  rescue nil
      return nil  unless json
      obj = JSON.parse(json)
      klass = Object.const_get(obj.delete("_class"))  rescue nil
      return nil  unless klass
      klass.from_hash(obj)  # rescue nil
    end

    def store(obj)
      obj._id ||= genid
      json = JSON.generate(obj)
      File.open(File.join(@dir, obj._id + ".json"), "wb") { |out| out << json }
      obj
    end

    def delete(id)
      begin
        File.delete(File.join(@dir, id + ".json"))
        true
      rescue SystemCallError
        false
      end
    end

    def genid
      id = nil
      until id && !fetch("id" => id)
        id = (0..6).map { ?a + rand(26) }.pack("C*")
      end
      id
    end
  end

  class JSONIndex < Relation
    def initialize(dir, of, fields=["_id"])
      @dir = File.expand_path(dir)
      @of = of
      @fields = fields
      FileUtils.mkdir_p(dir)
      reload
    end

    def reload
      @indexes = {}

      @fields.each { |field|
        @indexes[field] =
        JSON.load(File.read(File.join(@dir, field + ".index.json"))) rescue {}
      }
      @indexes.keys
    end

    def fetch(args)
      ids = nil
      args.each { |key, value|
        if ids.nil?
          ids = @indexes[key][value]
        else
          ids &= @indexes[key][value]
        end
      }
      @of.fetch("id" => ids.first)
    end

    def fetch_all(args)
      ids = nil
      args.each { |key, value|
        if ids.nil?
          ids = @indexes[key][value]
        else
          ids &= @indexes[key][value]
        end
      }
      ids.to_a.map { |id| @of.fetch("id" => id) }
    end

    def store(obj)
      @fields.each { |key|
        value = obj.__send__(key)
        (@indexes[key][value] ||= []) << obj._id
        @indexes[key][value].uniq!
      }
      flush
      obj
    end

    def delete(id)
      @indexes.each { |name, data|
        data.each { |key, values|    # XXX expensive
          values.delete id
        }
      }
      flush
      true
    end

    def flush
      @indexes.each { |name, data|
        json = JSON.generate data
        File.open(File.join(@dir, "#{name}.index.json"), "wb") { |out|
          out << json
        }
      }
      @indexes.keys
    end
  end
end
