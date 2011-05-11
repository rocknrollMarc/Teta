require_relative 'location'
require_relative 'help_system'
require_relative 'action_container'
require_relative 'game_context'
require_relative 'string_ext'
require_relative 'dsl/loader'

include DSL::Loader

class Runner < GameContext
  include ActionContainer

  attr_reader :previous_location
  attr_accessor :locations, :location

  DEBUG = true
  STORY_FOLDER = "../story/"

  def initialize
    super
  
    @player  = Player.new
    @help    = HelpSystem.new
    @running = true

    add_action :quit, :exit do
      @running = false
    end

    add_action :help do |cmd|
      @help.call cmd
    end
    
    add_action :go do |dir|
      case dir
      when 'back', 'b'
        if @previous_location && @location.connected?(@previous_location) then
          change_location @previous_location
          print_location
        else
          puts 'This is impossible!' 
        end
      else
        puts "I can't do that."
      end
    end

    add_action :inv do
      if player.items.length > 0 then
        @player.items.each do |item|
          puts "1x #{item.long_name}"
        end
      else
        puts '~ empty ~'
      end
    end

    add_action :g, :goto do |location_name|
      available_locations = location.connected_locations

      if location_name then
        loc = available_locations.find {|child| child.name == location_name.intern}

        # Allow the user to enter 'fi' to go to 'fire':
        if not loc then
          loc = available_locations.find {|child| child.name.to_s.start_set.include? location_name.to_s } 
        end
      else
        loc = nil
      end

      if loc then
        change_location loc
        
        puts
        print_location
      else
        puts "I can't go there." unless location_name == nil
        available_locations.each {|l| puts "    #{l.name}"}        
      end
    end

    add_action :look, :lookat do |item_name|
    
      if item_name then
        item = player.find_item_named_like item_name

        if item then
          if item.description then
            puts item.description
          else
            puts 'There is nothing special about this item.'
          end
        else
          puts 'Nothing to look at.'
        end

      else
        print_location
      end

    end
 
   if DEBUG then
     add_action :music do |name|
       MusicBox::play name
     end

     add_action :changechapter do |index|
       change_to_chapter index
       print_location
     end
   end
   
  end

  def run
    print_location

    while @running do
      step
    end
  end

  def change_to_chapter(index)
    @locations = parse_file "#{STORY_FOLDER}/chapter_#{index}.rb"
    @location = nil

    change_location locations.first
  end

  def die(reason = 'You died..')
     puts reason
     @running = false
  end

  def read_input
     print '> '
     gets.chomp    
  end

  def print_text(dirty_text)
    if not dirty_text.nil? then
      lines = dirty_text.split("\n").map {|line| line.strip }
      text = lines.join "\n"
    
      puts text
    end
  end

private
  def step
      handle read_input
  end

  def handle(input)
    entries = input.split ' '
   
    if entries.length > 0 then
      action = entries.first.intern
      args   = entries[1..entries.length]
   
      if not handle_action(action, args) then
        puts "Huh..?"
      end
    end
  end

  def handle_action(action, args)
    location.eval_action_safe(action, *args) or self.eval_action_safe(action, *args)
  end

  def print_location  
    print_text @location.description 
  end

  def change_location(loc)
    @previous_location = @location

    @location = loc
    setup_location

    transition = @location.find_transition_from(@previous_location)
    if transition != nil then
      transition.enter()
      puts transition.text unless transition.text.nil?
    end

  end

  def setup_location
    @location.context = self
  end

end
