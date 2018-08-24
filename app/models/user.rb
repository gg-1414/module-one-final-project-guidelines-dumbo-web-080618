require 'pry'
require 'pastel'
require 'ruby_figlet'
require 'catpix'
require 'terminal-table'

class User < ActiveRecord::Base
  has_many :reading_cards

  def wel_word
    pastel = Pastel.new(enabled: true)
    color = RubyFiglet::Figlet.new('Tarot House', 'Electronic')
    puts pastel.red(color)
  end

  def welcome
    pid = fork { exec 'afplay', './sound/test.mp3' }
    prompt = TTY::Prompt.new(active_color: :on_red)
    w = prompt.select(wel_word, marker: '❤') do |menu|
      menu.choices 'Existing User' => 'existing', 'New User' => 'newuser', Exit: 'exit'
    end

    case w
    when 'existing'
      user = existing
    when 'newuser'
      user = new_user
    when 'exit'
      lucky_number
      exit
      end
    puts `clear`
    menu(user)
  end

  def existing
    puts 'Please enter your name:'
    username = gets.downcase.chomp
    if !User.exists?(name: username)
      # puts "We don't have a #{username} on file. Would you like to create a new account?"
      prompt = TTY::Prompt.new
      w = prompt.select("We don't have a #{username} on file. Would you like to create a new account?") do |menu|
        menu.choices 'Yes' => 'yes', 'No' => 'no'
      end
      case w
      when 'yes'
        user = new_user(username)
      when 'no'
        lucky_number
        exit
      end
    else
      user = User.find_by(name: username)
    end
    user
  end

  def new_user(username = nil)
    puts 'Please enter your name:'
    username = gets.downcase.chomp
    if User.find_by(name: username.downcase)
      puts `clear`
      puts 'Username already exists.'
      welcome
    end
    User.create(name: username)
  end

  def main_menu(hash)
    prompt = TTY::Prompt.new(active_color: :on_red)
    choice = prompt.select(hash[:display], marker: '❤') do |menu|
      menu.choices hash[:choices]
    end
    choice
  end

  def menu(user)
    user = User.find(user.id)
    choice = main_menu display: 'Select option:',
                       choices: {
                         'Read My Tarot' => 'read',
                         'Tarot History' => 'history',
                         'Log Out' => 'exit'
                       }
    case choice
    when 'read'
      puts 'What would you like to know today?'
      category_menu(user)
    when 'history'
      history(user)
    when 'exit'
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
    pastel = Pastel.new
    puts pastel.yellow("Please pick a topic,")
    prompt = TTY::Prompt.new(active_color: :on_red)
    w = prompt.select(user.name.to_s, marker: '❤') do |menu|
      menu.choices 'Love' => 'love', 'Future' => 'future', 'Career' => 'career', 'Self' => 'self', 'Back' => 'back'
    end
    puts `clear`

    case w
    when 'love'
      found_card = nil
      num = Random.rand(0..4)
      Card.love_cards.each_with_index do |c, i|
        found_card = c if i == num
      end

    when 'future'
      found_card = nil
      num = Random.rand(0..4)
      Card.future_cards.each_with_index do |c, i|
        found_card = c if i == num
      end

    when 'career'
      found_card = nil
      num = Random.rand(0..4)
      Card.career_cards.each_with_index do |c, i|
        found_card = c if i == num
      end

    when 'self'
      found_card = nil
      num = Random.rand(0..4)
      Card.self_cards.each_with_index do |c, i|
        found_card = c if i == num
      end

    when 'back'
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
      progress = '=' * (i / 5) unless i < 5
      printf(pastel.magenta("\rLoading card [%-20s] %d%% %s"), progress, i, pastel.yellow(spinner.next))
      sleep(0.03)
    end
    puts `clear`
    puts `clear`
    puts found_card.card_img
    card_name = found_card.name
    puts pastel.magenta(RubyFiglet::Figlet.new(card_name, 'thin'))

    puts pastel.yellow(found_card.saying)
    new_reading_card(user, found_card)
    menu(user)
  end

  def find_readings(user)
    ReadingCard.select { |rc| rc.user.id == user.id }
  end

  def find_cards(user)
    get_card_id = find_readings(user).map(&:card_id)
    get_card_id.map do |e|
      Card.all.select { |card| card.id == e }
    end.flatten
  end

  def category(user)
    find_cards(user).map(&:category)
  end

  def card_name(user)
    find_cards(user).map(&:name)
  end

  def card_saying(user)
    find_cards(user).map(&:saying)
  end

  def date(user)
    find_readings(user).map(&:date)
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
    1.upto(25) do |_i|
      printf(pastel.magenta("\rLoading History: %s"), pastel.yellow(spinner.next))
      sleep(0.1)
    end
    puts
    puts
    puts `clear`
    if find_readings(user) == []
      puts "You don't have a history,"
    else
      readings = ReadingCard.all.select { |rc| rc.user.id == user.id }
      rows = []
      for i in 0..category(user).size - 1
        rows << [date(user)[i].strftime('%Y-%m-%d'), category(user)[i].capitalize, card_name(user)[i], card_saying(user)[i]]
      end

      pastel = Pastel.new
      header = ['DATE', 'CATEGORY', 'CARD NAME', 'CARD SAYING']
      header = header.map { |h| pastel.magenta.bold(h) }
      title = pastel.red.bold('TAROT HISTORY')

      table = Terminal::Table.new
      table.title = title
      table.headings = header
      table.rows = rows
      table.style = { width: nil, border_x: '_', border_i: '★', alignment: :center }
      puts table
  end

    prompt = TTY::Prompt.new(active_color: :on_red)
    w = prompt.select(user.name.to_s, marker: '❤') do |menu|
      menu.choices 'Back' => 'back'
    end

    case w
    when 'back'
      puts `clear`
      menu(user)
    end
  end

  def lucky_number
    puts `clear`
    puts `clear`
    # window_l = ENV['COLUMN'].to_i
    # window_h = ENV['LINES'].to_i
    pastel = Pastel.new(enabled: true)
    puts "\n \n"
    abc = "Thank you for visiting Tarot House.\n".center(ENV['COLUMNS'].to_i)
    # puts "hello #{ENV['COLUMNS'].to_i}"
    # binding.pry
    puts abc.center(158) #211
    acb = "Here are your lucky numbers:\n".center(ENV['COLUMNS'].to_i)
    puts acb.center(158) #211
    number = 3.times.map { Random.rand(200).to_s }.insert(0, '                                                       ').join('      ')
    # binding.pry
    puts pastel.red.bold(RubyFiglet::Figlet.new(number, 'digital'))
    puts "\n"
    final_pic
    system 'killall afplay'
  end

  def final_pic
    pastel = Pastel.new
    puts pastel.green.bold("
                                                                    LINH & GINA
                                                          ──────────────────────▄█▀▀▀▀▀█▄
                                                          ────────────▄▄▄▄▄───█▀────────▀█
                                                          ───────────█────▀█▄█───────────▀█
                                                          ───────█───────────█────▀▀▄▄▄▀▀───█
                                                          ──────▐─────────────█─▀▀▀▄────▄───█
                                                          ──────▐─────────────█─────▀──▀─▀▄─█
                                                          ──────▐─────────────█─███▄────────█
                                                          ──────▐─────────────█────▀────██─▐
                                                          ──────▐─────────────█───────▄─────█▄▄
                                                          ──────▐────────────█─────────▌────██─▌
                                                          ──────▐─────────────█───▄▀─▄─▌───█───▌
                                                          ────────█────────────█───▄▄▄▄──█─────▌
                                                          ──────▄▀▀▄───▌───────██───────█▌─────▌
                                                          ────▄▀────█──▌────────▀▀█████▀▀──────▌
                                                          ──▄▀───────███▌──────────▌───────────▌
                                                          ▄▀────────────█─────────────────────█
                                                          █───────▄██▀▀▀▀─────────────────────▌
                                                          █────────▀▄──────▄▀▀▀▀▄────────────█
                                                          █──────────▀▄──▄▀──▄▄▄▀────────────▌
                                                          ▀▄───────────▀▀────█───────────────▌
                                                          █─▀▄────────────────▀▀▀▀▀▄─────────▌
                                                          █───▀▄▄───────────────▄▄▄▀─────────▌
    ")
  end
end
