require 'pry'
require 'tty-table'
require 'pastel'
require 'ruby_figlet'
require 'catpix'


class User < ActiveRecord::Base
  has_many :reading_cards

  def wel_word
    pastel = Pastel.new(enabled: true)
    color = RubyFiglet::Figlet.new("Tarot House", "Electronic")
    puts pastel.red(color)
  end

  def welcome
    prompt = TTY::Prompt.new(active_color: :on_red)
    w = prompt.select(wel_word, marker: "❤") do |menu|
         menu.choices "Existing User" => "existing", "New User" => "newuser", Exit: "exit"
     end

     case w
       when "existing"
         user = existing
       when "newuser"
         user = new_user
       when "exit"
         lucky_number
         exit
       end
     puts `clear`
     menu(user)
  end

  def existing
    puts "Please enter your name:"
    username = gets.downcase.chomp
      if !User.exists?(name: username)
        puts "We don't have a #{username} on file. Would you like to create a new account?"
        user = new_user(username)
      else
        user = User.find_by(name: username)
      end
      user
  end

  def new_user username = nil
    puts "Please enter your name:"
    username = gets.downcase.chomp
    if User.find_by(name: username.downcase)
      puts `clear`
      puts "Username already exists."
      welcome
    end
    User.create(name: username)
  end

  def main_menu(hash)
    prompt = TTY::Prompt.new(active_color: :on_red)
    choice = prompt.select(hash[:display], marker: "❤") do |menu|
      menu.choices hash[:choices]
    end
    choice
  end

  def menu(user)
    user = User.find(user.id)
    choice = main_menu display: "Select option:",
                      choices: {
                        "Read My Tarot" => "read",
                        "Tarot History" => "history",
                        "Log Out" => "exit"
                      }
    case choice
      when "read"
        puts "What would you like to know today?"
        category_menu(user)
      when "history"
        history(user)
      when "exit"
        lucky_number
        exit
      end
    end


  def new_reading_card(user, found_card)
    rc = ReadingCard.create(user_id: user.id, card_id: found_card.id, date: Date.today)
    rc.save
    rc
  end

  def category_menu(user)
    puts `clear`
    prompt = TTY::Prompt.new(active_color: :on_red)
    w = prompt.select("#{user.name}", marker: "❤") do |menu|
      menu.choices "Love" => "love", "Future" => "future", "Career" => "career", "Self" => "self", "Back" => "back"
   end

   case w
     when "love"
       found_card = nil
       num = Random.rand(0..4)
       Card.love_cards.each_with_index do |c, i|
         if i == num
           found_card = c
         end
       end

     when "future"
       found_card = nil
       num = Random.rand(0..4)
       Card.future_cards.each_with_index do |c, i|
         if i == num
           found_card = c
         end
       end

     when "career"
       found_card = nil
       num = Random.rand(0..4)
       Card.career_cards.each_with_index do |c, i|
         if i == num
           found_card = c
         end
       end

     when "self"
       found_card = nil
       num = Random.rand(0..4)
       Card.self_cards.each_with_index do |c, i|
         if i == num
           found_card = c
         end
      end

     when "back"
       menu(user)
     end

     pastel = Pastel.new(enabled: true)
     spinner = Enumerator.new do |e|
       loop do
         e.yield '|'
         e.yield '/'
         e.yield '-'
         e.yield '\\'
       end
     end

    1.upto(100) do |i|
      progress = "=" * (i/5) unless i < 5
      printf("\rLoading card [%-20s] %d%% %s", progress, i, pastel.yellow(spinner.next))
      sleep(0.03)
    end
    puts `clear`
    puts `clear`
    found_card.card_img
    card_name = found_card.name.insert(0,"                     ")
    puts RubyFiglet::Figlet.new(card_name, "contessa")

    #
    puts found_card.saying
    new_reading_card(user, found_card)
    menu(user)
  end

  def find_readings(user)
    ReadingCard.select { |rc| rc.user.id == user.id }
  end

  def find_cards(user)
    get_card_id = self.find_readings(user).map { |rc| rc.card_id }
    get_card_id.map do |e|
      Card.all.select { |card| card.id == e }
    end.flatten
  end

  def category(user)
    self.find_cards(user).map { |e| e.category }
  end

  def card_name(user)
    self.find_cards(user).map { |e| e.name }
  end

  def card_saying(user)
    self.find_cards(user).map { |e| e.saying }
  end

  def date(user)
    self.find_readings(user).map { |e| e.date }
  end

  def history(user)
    puts `clear`
      pastel = Pastel.new(enabled: true)
      spinner = Enumerator.new do |e|
      loop do
        e.yield '|'
        e.yield '/'
        e.yield '-'
        e.yield '\\'
      end
    end
    # puts pastel.red(spinner)
    1.upto(25) do |i|
      printf("\rLoading History: %s", pastel.yellow(spinner.next))
      sleep(0.1)
    end
      puts
      puts
      puts `clear`
    if find_readings(user) == []
      puts "You don't have a history,"
    else

    readings = ReadingCard.all.select {|rc| rc.user.id == user.id }
    rows = []
    for i in 0..category(user).size-1
      rows << [date(user)[i].strftime('%Y-%m-%d'), category(user)[i].capitalize, card_name(user)[i], card_saying(user)[i]]
    end

    pastel = Pastel.new
    header = ["DATE", "CATEGORY", "CARD NAME", "CARD SAYING"]
    header = header.map {|h| pastel.magenta(h)}
    table = TTY::Table.new header, rows
    # puts table.render(:ascii, alignments: :center, padding: 1) do |renderer|
    #   renderer.filter = proc do |val, row_index, col_index|
    #     pastel.red.on_green(val)
    #   end
    # end

    puts table.render(:ascii, alignments: :center, padding: 1)
    # pastel = Pastel.new
    # puts table.render(:ascii, alignments: :center, padding: 1) do |renderer|
    #   pastel.renderer.border.color = :green
    # end
  end
    w = TTY::Prompt.new.select("#{user.name}") do |menu|
      menu.choices "Back" => "back"
   end
   case w
   when "back"
     puts `clear`
     menu(user)
   end
  end

  def lucky_number
    puts `clear`
    puts `clear`
    pastel = Pastel.new(enabled: true)
    puts "\n \n"
    puts "                                         Thank you for visiting Tarot House.\n\n"
    puts "                                            Here are your lucky numbers:\n\n"
    number = 3.times.map { Random.rand(200).to_s }.insert(0, "                                   ").join("      ")
    # binding.pry
    puts pastel.red(RubyFiglet::Figlet.new(number, "digital"))
    puts "\n \n"
    puts RubyFiglet::Figlet.new("Linh Gina", "isometric3")
  end

end
