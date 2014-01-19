#! /usr/bin/env ruby
require 'neography'
require 'imdb/parser'


# Usage: pv actors.list | ./data_loader <neo4j host>
class Application
  def run
    create_indexes
    parser.each {|actor| load_actor(actor)}
  end

  def load_actor(actor)
    node = neo.create_unique_node('actors', 'name', actor.name, fix({
      name: actor.name
    }))
    neo.set_label(node, "Actor")
    actor.roles.select {|r| r.type == :movie }.each do |role|
      begin
        movie = neo.create_unique_node('movies', 'title', role.title, fix({
          title: role.title,
          year: role.year
        }))
        neo.set_label(movie, "Movie")
        neo.create_relationship("ACTED_IN", node, movie, fix({
          character: role.character
        }))
      rescue
        puts fix({
          title: role.title,
          year: role.year
        })
        puts fix({
          character: role.character
        })
        raise
      end
    end
  end

  def create_indexes
    neo.create_schema_index("Actor", ["name"]) unless neo.get_schema_index("Actor")
    neo.create_schema_index("Movie", ["title"]) unless neo.get_schema_index("Movie")
  end

  attr_reader :parser, :neo
  def initialize
    @parser = IMDB::Parser::Parser.new(IO.new($stdin.fileno, 'r:ISO-8859-1'))
    @neo = Neography::Rest.new
  end

  private

  def fix(h)
    Hash[h.reject{|k,v| v.nil?}]
  end
end


Neography.configure do |config|
  config.server = ARGV[0] if ARGV
end
Application.new.run
