require 'yaml'
require 'json'
class Minesweeper

  attr_reader :board, :shown, :flags

  def initialize(n = 9)
    @num_bombs = (n == 9 ? 10 : 40)
    @board = generate_board(9)
    @flags = []
    @shown = []
    @timer = []
  end

  # runs through game methods until the game has been lost or won
  def play_game
    timer
    until has_won?
      print_board
      puts "Enter coordinates separated by a comma (e.g. 0,0):"
      coordinates = gets.chomp.split(",").map!{|x| x.to_i}
      puts "Enter r - reveal, f - flag, save - saves game:"
      response = gets.chomp.downcase
      if response == 'save'
        puts "Game saved as: #{save_game}"
        return nil
      elsif response == 'r'
        if !process_move(*coordinates)
          puts "You Lose. Your time was #{time_diff}"
          return nil
        end
      else
        mark_flag(*coordinates)
      end
    end
    timer
    puts "You Win! Your time was #{time_diff}"
  end

  def has_won?
    @shown.length == @board.length ** 2 - @num_bombs
  end

  def mark_flag(y,x)
    @flags << [y,x]
  end

  # creates a user readable board
  # :admin argument will reveal all bombs and adjacent numbers
  def print_board(mode = :player)
    print "  "
    @board.length.times {|i| print "[#{i}]"}

    @board.each_with_index do |row, row_ind|
      print "\n#{row_ind}  "
      row.each_index do |col_ind|
        elem = @board[row_ind][col_ind]
        if @shown.include?([row_ind, col_ind]) || mode == :admin
           elem == 0 ? (print "-  ") : (print "#{elem}  ")
        else
          @flags.include?([row_ind, col_ind]) ? (print "F  ") : (print "*  ")
        end
      end
    end
  end

  # determines what is revealed on board based on initial cell chosen
  def process_move(y, x, action = :reveal)
    case @board[y][x]
    when :B
      print_board(:admin)
      timer
      return false
    when 0
      find_empty_area(y, x)
    else
      @shown << [y,x]
    end
  end

  # determines which cells to reveal based on the y & x coordinates
  # method will reveal cells up to a cell containing a number
  # will not reveal flags or bombs
  def find_empty_area(y, x)
    adj = find_adjacent(y, x, @board)
    off_y, off_x = *adj.shift

    adj.first.each_with_index do |row, row_i|
      row.each_with_index do |elem, col_i|
        true_coord = [row_i + off_y, col_i + off_x]

        if elem == 0 && !@shown.include?(true_coord)
          @shown << true_coord unless (@shown + @flags).include?(true_coord)
          find_empty_area(*true_coord)
        else
          @shown << true_coord unless (@shown + @flags).include?(true_coord)
        end

      end
    end
  end

  # creates a new board with bombs and number of adjacent bombs per cell
  # take a single integer of the length/width of the board
  def generate_board(n)
    board = Array.new(n) { Array.new(n) }
    until board.flatten.count(:B) == @num_bombs
      board[rand(n-1)][rand(n-1)] = :B
    end
    fill_board_numbers(board)
  end

  # takes an array of bombs and fills board with the number of adjacent bombs
  # per cell
  def fill_board_numbers(array)
    (0...array.length).each do |y|
      (0...array.length).each do |x|
        if array[y][x].nil?
          adjacent = find_adjacent(y, x, array)
          array[y][x] = adjacent[1].flatten.count(:B)
        end
      end
    end
    array
  end

  # returns 3x3 (or 2x2 for corners) array of adjacent tiles along with
  # the index offset of the tiles relative to the entire board
  def find_adjacent(y, x, array)
    len = array.count - 1
    y_max = (y == len ? y : y + 1)
    x_max = (x == len ? x : x + 1)
    y_min = (y == 0 ? y : y - 1)
    x_min = (x == 0 ? x : x - 1)
    adjacent = [offset(y,x),[]]

    array[y_min..y_max].each { |arr| adjacent[1] << arr[x_min..x_max] }
    adjacent
  end

  # calculates the index offset for a given index
  def offset(y,x)
    off_y = (y == 0 ? y : y - 1)
    off_x = (x == 0 ? x : x - 1)
    [off_y, off_x]
  end

  # pushes current time to stack
  def timer
    @timer << Time.now
  end

  # calculates the total time spent on the game, taking into account stoppage
  # due to saved games, etc.
  def time_diff
    time = 0
    until @timer.empty?
      time += @timer.pop - @timer.pop
    end
    time.round(2)
  end

  # functionality for saving games
  def save_game
    timer
    puts "What would you like to save it as?"
    file_name = gets.chomp
    file = File.open("#{file_name}.yml",'w')
    file.puts self.to_yaml
    file.close
    return "#{file_name}.yml"
  end

  # load game from YAML
  def self.load_game(file_name)
    f = File.open("#{file_name}", 'r')
    YAML::load(f)
  end

=begin

  # Incomplete attempt at high scores list using json for serialization

  def self.get_high_scores
    f = File.readlines("high_scores.json")
    f.each do |line|
      print_scores(JSON.parse(line))
    end
  end

  def print_scores(score_hash)
    puts "=== #{score_hash[:title]} ==="
    score_hash.sort_by {|key, value| value }.each do |pair|
      print "#{pair[0]}\t#{pair[1]}" unless pair[0] == :title
    end
  end

  def add_high_score(name, time)
    scores =  f = File.readlines("high_scores.json")
    f.each do |line|
      a = JSON.parse(line)
      break if a[:title].include?(@board.length)
    end
    f.close
    a[name] = time
    hs = a.sort_by {|key, value| value}
    hs.pop if hs.length > 10
    high_score_hash = {}
    hs.each do |entry|
      high_score_hash[entry[0]] = entry[1]
    end
    print_scores(high_score_hash)
    f = File.open("high_scores.json", "w")
    f.puts high_score_hash.to_json
  end
end
=end

# Menu function

def main_menu
  ans = ''
  loop do
    puts "[1] New 9x9 Game"
    puts "[2] New 16x16 Game"
    puts "[3] Load Game"
    puts "[4] Quit"
    ans = gets.chomp.to_i
    return Minesweeper.new if ans == 1
    return Minesweeper.new(16) if ans == 2
    if ans == 3
      puts "Enter your saved game filename (e.g. mygame.yml)"
      return Minesweeper.load_game(gets.chomp)
    elsif ans != 4
      puts "Invalid Option. Please select [1-5]."
    end
  end while ans != 4
end

if __FILE__ == $PROGRAM_NAME
  m = main_menu
  m.play_game
end
