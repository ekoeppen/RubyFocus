#!/usr/bin/env ruby

require 'curses'

class Line
    attr_accessor :action
    attr_accessor :active

    def initialize(theAction, isActive = nil)
      @action = theAction
      @active = isActive
    end
end

class Page
  
  attr_accessor :lines
  attr_accessor :number
  
  def initialize
    @lines = Array.new
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
    
    @pages << page
    @current_page = page
    @current_line = 0
  end

  def show_page
    i = 0
    for l in @current_page.lines do
      Curses.setpos(i, 0)
      Curses.addstr(if i == @current_line then "-> " else "   " end)
      if l.active then Curses.stdscr.color_set(1) end
      Curses.addstr(l.action)
      if l.active then Curses.stdscr.color_set(0) end
      i = i + 1
    end
    Curses.refresh
  end

  def initialize
    @pages = Array.new
    generate_test_data
    init_screen do
      loop do
        show_page
        case Curses.getch
        when Curses::Key::UP then if @current_line > 0 then @current_line = @current_line - 1 end
        when Curses::Key::DOWN then  if @current_line < @current_page.lines.length - 1 then @current_line = @current_line + 1 end
#        when Curses::Key::RIGHT then end
#        when Curses::Key::LEFT then end
        when ?a then begin
          Curses.echo; Curses.curs_set(1)
          Curses.setpos(10, 0)
          @current_page.lines << Line.new(Curses.getstr)
          Curses.noecho; Curses.curs_set(0)
        end
        when ?s then begin
          l = @current_page.lines.at(@current_line)
          l.active = l.active
        end
        when ?q then break
        end
      end
    end

  end
  
end

RubyFocus.new()

# vim:ts=2:expandtab:sw=2:

