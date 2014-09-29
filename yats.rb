require 'aws-sdk-core'
require 'curses'
require 'pry'

EC2_LIST_CACHE_TIME_IN_SECONDS = 86400 # One day
EC2_LIST_CACHE_FILENAME = "cached_ec2_list.txt"

class YetAnotherThingForSSH
  def initialize
    @ec2 = Aws::EC2::Client.new
    @my_instances = all_my_instances
    run
  end

  def run
    find_instances_by terms: ARGV
  end

  def find_instances_by(terms: nil)
    matches = @my_instances
                .map { |instance|
                    name = instance["tags"].select { |tag|
                        tag["key"] == "Name"
                    }.first["value"] rescue ""
                    {
                      ip: instance["private_ip_address"],
                      name: name
                    }
                }
                .reject { |match|
                  [
                    match[:ip] == "",
                    match[:ip].nil?,
                    match[:name] == "",
                    match[:name].nil?
                  ].any?
                }
                .select { |instance|
                  terms.all? { |term|
                    instance[:name].include? term 
                  }
                }
                .sort_by { |instance|
                   instance[:name]
                }
    configure_curses
    cursor_pos = 0
    selected_items = []
    begin
      loop do
        draw_list instances: matches, cursor_pos: cursor_pos, selected_items: selected_items, terms: terms
        Curses.setpos(cursor_pos,0)
        in_char = Curses.getch
        break if in_char == 27 # Escape
        if in_char == 'j' || in_char == 258 # down
          if cursor_pos < matches.size
            cursor_pos += 1
          end
        elsif in_char == 'k' || in_char == 259 # up
          if cursor_pos > 0
            cursor_pos -= 1
          end
        elsif in_char == 10 # Enter
          selected_items.each do |index|
            ip = matches[index][:ip]
            ssh_connect_to server: ip
          end
          break
        elsif in_char == ' '
          if selected_items.include? cursor_pos
            selected_items.delete cursor_pos
          else
            selected_items << cursor_pos
          end
        end
      end
    ensure
      Curses.close_screen
    end
  end

  def configure_curses
    Curses.noecho
    Curses.init_screen
    Curses.raw
    Curses.stdscr.keypad(true)
    Curses.curs_set(1)
    Curses.start_color
    Curses.init_pair(Curses::COLOR_RED,Curses::COLOR_RED,Curses::COLOR_BLACK)
    Curses.init_pair(Curses::COLOR_WHITE,Curses::COLOR_WHITE,Curses::COLOR_BLACK)
    Curses.init_pair(Curses::COLOR_BLUE,Curses::COLOR_WHITE,Curses::COLOR_BLUE)
  end

  def draw_list(instances: nil, cursor_pos: nil, selected_items: nil, terms: terms)
    instances.each_with_index do |instance, index|
      Curses.setpos(index, 0)
      normal_color = selected_items.include?(index)? Curses::COLOR_BLUE : Curses::COLOR_WHITE
      instance[:name].split(/#{ "(" + terms.join(")|(") + ")" }/).each do |token|
        if terms.include? token
          Curses.attron(Curses.color_pair(Curses::COLOR_RED)|Curses::A_NORMAL){
            Curses.addstr(token)
          }
        else
          Curses.attron(Curses.color_pair(normal_color)|Curses::A_NORMAL){
            Curses.addstr(token)
          }
        end
      end
    end
  end

  def all_my_instances
    # Check if we have a cached version
    cached_file = reload_cached_file
    if cached_file["expires"] && cached_file["expires"] > Time.now.to_i
      puts "Loaded EC2 list from file"
    else
      reservations = @ec2.describe_instances.reservations
      instances = reservations.map { |reservation| reservation.instances }.flatten.map { |instance| instance.to_h } rescue []
      File.write("#{File.dirname(__FILE__)}/#{EC2_LIST_CACHE_FILENAME}", {
        expires: Time.now.to_i + EC2_LIST_CACHE_TIME_IN_SECONDS,
        instances: instances
        }.to_json)
      puts "Loaded EC2 list from Amazon"
      cached_file = reload_cached_file
    end
    cached_file["instances"]
  end

  def reload_cached_file
    JSON.parse(File.read("#{File.dirname(__FILE__)}/#{EC2_LIST_CACHE_FILENAME}")) rescue {}
  end

  def ssh_connect_to(server: nil)
    if ENV["YATS_USERNAME"]
      command = "ssh #{ENV["YATS_USERNAME"]}@#{server}"
    else
      command = "ssh #{server}"
    end
    run_terminal_with command: command
  end

  def run_terminal_with(command: nil)
    %x(osascript -e 'tell app "Terminal"
              do script "#{command}"
            end tell')
  end
end

YetAnotherThingForSSH.new

