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
  @@k_max_length = 20

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
  attr_accessor :use_color
  attr_accessor :dismissed
 
  def init_colors
    @use_color = nil
    if @use_color
      Curses.start_color
      Curses.init_pair(1, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
      Curses.init_pair(2, Curses::COLOR_RED, Curses::COLOR_BLACK)
      Curses.init_pair(3, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    end
    set_normal_color
  end
  
  def set_normal_color
    if @use_color then Curses.stdscr.color_set(1) else Curses.stdscr.attrset(Curses::A_BOLD) end
  end
  
  def set_active_color
    if @use_color then Curses.stdscr.color_set(2) else Curses.stdscr.attrset(Curses::A_STANDOUT) end
  end
  
  def set_done_color
    if @use_color then Curses.stdscr.color_set(3) else Curses.stdscr.attrset(Curses::A_DIM) end
  end
  
  def initialize
    @pages = Array.new
    @pages << Page.new
    @current_page = 0
    @current_line = 0
  end

  def init_screen
    Curses.noecho
    Curses.init_screen
    Curses.stdscr.keypad(true)
    Curses.curs_set(0)
    init_colors
    begin
      yield
    ensure
      Curses.close_screen
    end
  end
  
  def enter_action(action = nil)
    clear = false
    i = @current_page
    while i < pages.length and @pages[i].lines.length >= Page.max_length
      i = i + 1
    end
    if i >= pages.length
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

  def done_action
    a = @pages[@current_page].lines[@current_line]
    a.state = 2
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
        set_active_color
      elsif l.state == 2
        set_done_color
      end
      Curses.addstr(l.action)
      if l.state != 0 then
        set_normal_color
      end
      Curses.clrtoeol
      i = i + 1
    end
    while i < Page.max_length
      Curses.setpos(i + 2, 0)
      Curses.clrtoeol
      i = i + 1
    end
    Curses.refresh
  end

  def page_forward
    if @current_page < pages.length - 1
      @current_page = @current_page + 1
    else
      @current_page = 0
    end
    @current_line = 0
  end

  def page_backward
    if @current_page > 0 then
      @current_page = @current_page - 1
    else
      @current_page = pages.length - 1
    end
    @current_line = 0
  end
  
  def next_line
    if @current_line < @pages[@current_page].lines.length - 1
      begin
        @current_line = @current_line + 1
      end # while @current_line < @pages[@current_page].lines.length - 1 and @pages[@current_page].lines[@current_line].state == 2
    end
  end
  
  def previous_line
    if @current_line > 0 then
      begin
        @current_line = @current_line - 1
      end # while @current_line > 0 and @pages[@current_page].lines[@current_line].state == 2
    end
  end

  def dismiss_page
    @pages[@current_page].lines.each do |a|
      @dismissed << a.action if a.state < 2
    end
    @pages.delete_at(@current_page)
    if @current_page == @pages.length then @current_page = @current_page - 1 end
    if @current_page == -1
      @current_page = 0
      @pages << Page.new
    end
  end
  
  def to_s
    r = ""
    r << "=========================================================================\n"
    dismissed.each do |line|
      r << "  " << line << "\n"
    end
    i = 0
    @pages.each do |page|
      r << "---"
      if i == @current_page then r << " X " else r << "---" end
      r <<"-------------------------------------------------------------------\n"
      page.lines.each do |line|
        if line.state == 1 then prefix = "+ "
        elsif line.state == 2 then prefix = "- "
        else prefix = "  "
        end
        r << prefix << line.action << "\n"
      end
      i = i + 1
    end
    return r
  end
  
  def from_s(string)
    @pages = Array.new
    reading_dismissed = true
    page = nil
    state = 0
    i = 0
    string.each_line do |line|
      line.rstrip!
      if line.start_with? "===" then
        @dismissed = Array.new
      elsif line.start_with? "---" then
        reading_dismissed = false
        page = Page.new
        @pages << page
        if line.start_with? "--- X"
          @current_page = i
        end
        i = i + 1
      else
        if reading_dismissed
          line.slice!(0..1)
          dismissed << line
        else
          if line.start_with? "  "
            state = 0
          elsif line.start_with? "+ "
            state = 1
          else
            state = 2
          end
          line.slice!(0..1)
          page.lines << Line.new(line, state)
        end
      end
    end
    @current_line = 0
  end

  def save_data
    File.open("pages.yaml", "w") do |file|
      file.syswrite(self.to_yaml)
    end
    File.open("pages.txt", "w") do |file|
      file << to_s
    end
  end
  
  def RubyFocus.load_data
    f = nil
    begin
#      File.open("pages.yaml", "r") do |file|
#        f = YAML::load(file.read)
#      end
      File.open("pages.txt") do |file|
        f = RubyFocus.new
        f.from_s(file.read)
      end
    rescue
      f = RubyFocus.new
    end
    return f
  end

  def run
    init_screen do
      loop do
        page = @pages.at(@current_page)
        show_page
        c = Curses.getch
        case c
        when Curses::Key::UP then previous_line
        when Curses::Key::DOWN then next_line
        when Curses::Key::LEFT then page_backward
        when Curses::Key::RIGHT then page_forward
        when ?e then edit_action
        when ?a then enter_action
        when ?s then toggle_action
        when ?d then done_action
        when ?D then dismiss_page
        when ?q then save_data; break
        end
        if c != Curses::Key::UP and c != Curses::Key::DOWN
          save_data
        end
      end
    end

  end
  
end

if File.exist?(ENV["HOME"] + "/.rubyfocusrc") then load(ENV["HOME"] + "/.rubyfocusrc") end

RubyFocus.load_data.run

# vim:ts=2:expandtab:sw=2:

