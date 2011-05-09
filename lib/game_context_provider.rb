require_relative 'game_context'
require_relative 'music_box'
require_relative 'dsl/choices'

module GameContextProvider
  include Choices

  attr_accessor :context

  def player
    context.player
  end

  # 
  # DSL hooks:
  #
  def remove_player(item, expected_item)
    item = item.intern

    if item == expected_item then
      player.remove_item item
    else
      nil
    end
  end

  def unknown
    puts 'Huh..?'
  end

  def read_input
    context.read_input
  end

  def println(text)
    context.print_text text
  end

  def music(name)
     MusicBox.play name
  end
  
  def give_new_item(name, description=nil)
    item = context.item_factory.create(name)

    if description != nil then
      item.description = description
    end

    if block_given? then
      block = Proc.new
      item.instance_eval &block
    end

    player.add_item item
  end
  
  def change_to_chapter(index)
    context.change_to_chapter index
  end
  
  def die
    context.die
  end
   
end
