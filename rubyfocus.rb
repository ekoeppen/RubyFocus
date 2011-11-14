#!/usr/bin/env ruby

require 'curses'
require 'yaml'

class Line
  attr_accessor :action
  attr_accessor :state

  def initialize(theAction, aState = 0)
    @action = theAction
    @state = aState
  end
end

class Page
  
  attr_accessor :lines
  attr_accessor :number
  @@k_max_length = 10

  def initialize
    @lines = Array.new
  end
  
  def Page.max_length
    return @@k_max_length
  end

end

class RubyFocus
  
  attr_accessor :pages
  attr_accessor :current_page
  attr_accessor :current_line

  def init_screen
    Curses.noecho
    Curses.init_screen
    Curses.start_color
    Curses.stdscr.keypad(true)
    Curses.curs_set(0)
    Curses.init_pair(0, Curses::COLOR_BLACK, Curses::COLOR_RED)
    Curses.init_pair(1, Curses::COLOR_RED, Curses::COLOR_BLACK)
    Curses.init_pair(2, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    Curses.stdscr.color_set(0)
    begin
      yield
    ensure
      Curses.close_screen
    end
  end

  def generate_test_data
    page = Page.new
    page.lines << Line.new("Line one")<< Line.new("Line two", true) << Line.new("Line three")
    page.lines << Line.new("Line one")<< Line.new("Line two") << Line.new("Line three")
    page.lines << Line.new("Line one")<< Line.new("Line two") << Line.new("Line three")
    
    @pages << page
    @current_page = 0
    @current_line = 0
  end

  def enter_action(action = nil)
    clear = false
    i = @current_page
    while @pages[i].lines.length > Page.max_length and i < pages.length 
      i = i + 1
    end
    if i == pages.length 
      @pages << Page.new
      @current_line = 0
    end
    if not action
      Curses.echo; Curses.curs_set(1)
      Curses.setpos(0, 0)
      Curses.addstr("New action: ")
      @pages[i].lines << Line.new(Curses.getstr)
      Curses.noecho; Curses.curs_set(0)
      Curses.setpos(0, 0)
      Curses.clrtoeol
    else
      @pages[i].lines << Line.new(action)
    end
  end

  def edit_action
    page = @pages.at(@current_page)
    Curses.echo; Curses.curs_set(1)
    Curses.setpos(0, 0)
    Curses.addstr("Edit action: ")
    page.lines[@current_line] = Line.new(Curses.getstr)
    Curses.noecho; Curses.curs_set(0)
    Curses.setpos(0, 0)
    Curses.clrtoeol
  end

  def toggle_action
    a = @pages[@current_page].lines[@current_line]
    if a.state < 2
      if a.state == 1
        enter_action(a.action)
      end
      a.state = a.state + 1
    end
  end

  def show_page
    i = 0
    for l in @pages.at(@current_page).lines do
      Curses.setpos(i + 2, 0)
      Curses.addstr(if i == @current_line then "-> " else "   " end)
      if l.state == 1
        Curses.stdscr.color_set(1)
      elsif l.state == 2
        Curses.stdscr.attrset(Curses::A_DIM)
      end
      Curses.addstr(l.action)
      if l.state != 0 then Curses.stdscr.color_set(0); Curses.stdscr.attrset(Curses::A_NORMAL) end
      i = i + 1
    end
    Curses.refresh
  end

  def page_forward
    if @current_page < pages.length - 1
      @current_page = @current_page + 1
      @current_line = 0
      Curses.clear
    end
  end

  def page_backward
    if @current_page > 0 then
      @current_page = @current_page - 1
      @current_line = 0
      Curses.clear
    end
  end

  def save_data
    File.open("pages.yaml", "w") do |file|
      file.syswrite(self.to_yaml)
    end
  end

  def RubyFocus.load_data
    focus = nil
    File.open("pages.yaml", "r") do |file|
      focus = YAML::load(file.read)
    end
    return focus
  end

  def run
    init_screen do
      loop do
        page = @pages.at(@current_page)
        show_page
        case Curses.getch
        when Curses::Key::UP then if @current_line > 0 then @current_line = @current_line - 1 end
        when Curses::Key::DOWN then if @current_line < page.lines.length - 1 then @current_line = @current_line + 1 end
        when Curses::Key::LEFT then page_backward
        when Curses::Key::RIGHT then page_forward
        when ?e then edit_action
        when ?a then enter_action
        when ?s then toggle_action
        when ?q then save_data; break
        end
      end
    end

  end
  
end

RubyFocus.load_data.run

# vim:ts=2:expandtab:sw=2:

