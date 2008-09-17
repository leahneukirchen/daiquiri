require 'daiquiri'
require 'daiquiri/json'

Tasks = Daiquiri::JSONFileStore.new("tasks")

ToDoLists = Daiquiri::JSONFileStore.new("lists")
AllToDoLists = Daiquiri::JSONIndex.new("lists", ToDoLists, ["x"])

class Task < Daiquiri::Resource
  include Daiquiri::Persistable

  attr_accessor :description
  attr_accessor :done
  attr_accessor :parent

  def initialize(description)
    @description = description
    @done = false
  end

  def save
    Tasks.store self
  end

  def load_parent
    ToDoLists.fetch("id" => parent)
  end

  def href
    "/task/#{_id}"
  end

  def finish
    self.done = true
    save
    res.redirect_back
  end
end

class ToDoList < Daiquiri::Resource
  include Daiquiri::SingletonRelation
  include Daiquiri::Persistable

  attr_accessor :title
  attr_accessor :items

  def load_items
    @items.map { |id| Tasks.fetch("id" => id) }
  end

  def x
    "todolist"
  end

  def index
    res.data.lists = AllToDoLists.fetch_all("x" => "todolist")
  end

  def show
    res.data.todolist = self
  end

  def add
    t = Task.new(req["description"])
    t.save
    @items << t._id
    save
    t.parent = self._id
    save

    p t
    p items

    res.redirect href
  end

  def create
    x = ToDoList.new
    x.title = req["title"]
    x.items = []
    x.save
    
    res.redirect x.href
  end

  def href
    "/#{_id}"
  end

  def save
    ToDoLists.store self
    AllToDoLists.store self
  end
end

list = ToDoList.new
ToDo = Daiquiri::Router.new \
  '/' => list,
  '/{id}' => ToDoLists,
  '/{id}/{action}' => ToDoLists,
  '/task/{id}' => Tasks,
  '/task/{id}/{action}' => Tasks
