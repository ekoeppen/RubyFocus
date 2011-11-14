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

  def enter_action
    page = @pages.at(@current_page)
    if page.lines.length > Page.max_length
      page = Page.new
      @pages << page
      @current_page = @current_page + 1
      @current_line = 0
      Curses.clear
    end
    Curses.echo; Curses.curs_set(1)
    Curses.setpos(0, 0)
    Curses.addstr("New action: ")
    page.lines << Line.new(Curses.getstr)
    Curses.noecho; Curses.curs_set(0)
    Curses.setpos(0, 0)
    Curses.clrtoeol
  end

  def show_page
    i = 0
    for l in @pages.at(@current_page).lines do
      Curses.setpos(i + 2, 0)
      Curses.addstr(if i == @current_line then "-> " else "   " end)
      if l.active then Curses.stdscr.color_set(1) end
      Curses.addstr(l.action)
      if l.active then Curses.stdscr.color_set(0) end
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

  def initialize
    @pages = Array.new
    generate_test_data
    init_screen do
      loop do
        page = @pages.at(@current_page)
        show_page
        case Curses.getch
        when Curses::Key::UP then if @current_line > 0 then @current_line = @current_line - 1 end
        when Curses::Key::DOWN then if @current_line < page.lines.length - 1 then @current_line = @current_line + 1 end
        when Curses::Key::LEFT then page_backward
        when Curses::Key::RIGHT then page_forward
        when ?a then enter_action
        when ?s then begin
          l = page.lines.at(@current_line)
          l.active = !l.active
        end
        when ?q then break
        end
      end
    end

  end
  
end

RubyFocus.new()

# vim:ts=2:expandtab:sw=2:

