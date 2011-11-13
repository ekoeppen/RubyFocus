#!/usr/bin/env ruby

require 'curses'

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

  def init_screen
    Curses.noecho
    Curses.init_screen
    Curses.stdscr.keypad(true)
    Curses.curs_set(0)
    begin
      yield
    ensure
      Curses.close_screen
    end
  end

  def generate_test_data
    page = Page.new
    page.lines << "Line one" << "Line two" << "Line three"
    
    @pages << page
    @current_page = page
  end

  def show_page
    i = 1
    for l in @current_page.lines do
      Curses.setpos(i, 3)
      Curses.addstr(l)
      i = i + 1
    end
  end

  def initialize
    @pages = Array.new
    generate_test_data

    init_screen do

      show_page

      loop do
        case Curses.getch
        when Curses::Key::UP then write(0, 0, "up")
        when Curses::Key::DOWN then write(0, 0, "down")
        when Curses::Key::RIGHT then write(0, 0, "left")
        when Curses::Key::LEFT then write(0, 0, "right")
        when ?a then begin
          Curses.echo; Curses.setpos (10, 0)
          Curses.curs_set(1)
          Curses.getstr
          Curses.curs_set(0)
          Curses.noecho
        end
        when ?q then break
        end
      end
    end

  end
  
end

RubyFocus.new()