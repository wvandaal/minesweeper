require 'yaml'
require 'json'
class Minesweeper

	#REV: Your game has a bug somewhere. When I run it I get an error that says
	#the process_move method has the wrong number of arguments.
  
  #Your code may be easier to manage if you break it up into separate classes.
  #You could make a main game_class that controls game operations and a board
  #class that keeps track of the board. 

  attr_reader :board, :shown, :flags

  def initialize(n = 9)
    @num_bombs = (n == 9 ? 10 : 40)
		
		#REV: You should pass n to generate_board so that you can generate
		#the 16X16 board if the user initializes the game with n = 16.
    @board = generate_board(9)
    @flags = []
    @shown = []
    @timer = []
  end

  # runs through game methods until the game has been lost or won
  def play_game
    timer
    until has_won?
			#REV: Maybe move all of the puts statements and ui stuff to a separate 
			#method like 'get_move' or something. Try to keep methods focused on
			#a single task. Also, you can wrap the ui stuff in a loop and break
			#out of it after you verify that the input is valid. Otherwise, 
			#your game might crash if the input isn't formatted right.
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
  			#REV: I think that you should use elsif instead of just else. The
        #current program would call mark_flag for anything typed in other than
        #save or r
      else
        mark_flag(*coordinates)
      end
    end
    timer
    puts "You Win! Your time was #{time_diff}"
  end

  def has_won?
		#REV: I'm not sure what you're doing here. Maybe add a comment.
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
		
		#REV: You can condense your file writing code into its own block like this
		#File.open(filename, 'w'){|f| f.puts self.to_yaml }.
    file = File.open("#{file_name}.yml",'w')
    file.puts self.to_yaml
    file.close
    return "#{file_name}.yml"
  end

  # load game from YAML
  def self.load_game(file_name)
		#REV: You can condense this into one line like this
		#YAML::load(File.read(filename)).
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
=end
#REV: I moved the end of your comment up. It was covering the end statement
#for your class and causing an error.	
end


# Menu function

def main_menu
	#REV: I don't think you need to declare ans here, since you only use it 
  #inside of the loop.
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
			
		#REV: What if ans == 4? You should probably just have an else here, since
		#you probably want to keep looping around until you get an answer between
		#1 and 3.	Also, you should probably reprompt them to select from 1-3, not 
    #1-5
    elsif ans != 4
      puts "Invalid Option. Please select [1-5]."
    end
		#REV: I'm not sure what the while statement is for but I think that you
		#don't need it. You should keep looping until you return as a result of 
    #the user entering 1, 2, or 3.	
  end while ans != 4
end

if __FILE__ == $PROGRAM_NAME
  m = main_menu
  m.play_game
end
