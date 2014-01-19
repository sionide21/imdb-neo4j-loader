#! /usr/bin/env ruby
require 'neography'
require 'imdb/parser'


# Usage: pv actors.list | ./data_loader.rb <neo4j host> <latest>
# Get the latest with "MATCH (a:Actor) RETURN a.name ORDER BY UPPER(a.name) DESC LIMIT 1"
class Application
  def run
    create_indexes
    fast_forward
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

  def fast_forward
    return unless latest
    ## Rerun the latest to ensure all movies are present
    load_actor(parser.find { |a| a.name == latest })
  end

  attr_reader :parser, :neo, :latest
  def initialize
    @parser = IMDB::Parser::Parser.new(IO.new($stdin.fileno, 'r:ISO-8859-1'))
    @latest = ARGV[1]
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
