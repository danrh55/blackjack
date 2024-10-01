require './hand'
require './table'

class Participant
  attr_accessor :hands, :status, :chips, :table

  MAX_NAME_LENGTH = 13

  def initialize(name)
    @name = name
    @chips = rand(100..1000)
    @table = nil
  end

  def name
    if @name.length <= MAX_NAME_LENGTH
      @name
    else
      "#{@name[0..10]}..."
    end
  end

  def to_s
    name
  end

  protected

  def capitalize_full_name(name)
    name.split.map(&:capitalize).join(' ')
  end
end

class Player < Participant
  def initialize(name)
    super(name)
    @hands = []
  end

  def move
    hands.each do |hand|
      next if hand.done?
      table.refresh
      move = choose_move(hand)
      table.dealer.deal_move(hand, move)
      break if move == 'split'
    end
  end

  def enough_chips?(bet_amount)
    if chips >= bet_amount.to_i
      true
    else
      puts "\n=> Not enough money!"
      false
    end
  end

  def centered_name(seat_length)
    name.center(seat_length)
  end

  def combined_hands
    hands.map do |hand|
      hand
    end.join(' ')
  end

  def combine_statuses
    hands.map(&:status).join(' ' * ((table.seat_length / 2) - 7))
  end

  def combine_bets
    hands.map do |hand|
      "Bet: #{hand.bet_amount}"
    end.join(' ' * ((table.seat_length / 2) - 7))
  end

  def done?
    hands.all?(&:done?)
  end

  def broke?
    chips == 0
  end

  def play_again?
    answer = nil

    loop do
      table.refresh
      puts "#{name} would you like to player another round? (y/n)"
      answer = gets.chomp.strip.downcase
      break if ['y', 'n'].include?(answer)
      puts "Invalid input. Please try again."
    end
    answer == 'y'
  end

  private

  def choose_move(hand)
    loop do
      table.refresh
      puts "#{name}, what's your move for #{hand}?"
      print 'Move: '
      move = gets.chomp.strip.downcase
      return move if hand.valid_move?(move)
    end
  end
end

class Dealer < Participant
  attr_accessor :hand

  def initialize(name)
    super(name)
    @hand = nil
  end

  def remove_broke_players
    table.seats.each do |seat_num, player|
      next if player.nil?
      if player.broke?
        puts "\n\n=> #{player.name} leaves as they are out of money. :("
        sleep 1
        table.seats[seat_num] = nil
      end
    end
  end

  def prompt_another_round
    table.seats.each do |seat_num, player|
      next if player.nil?
      table.seats[seat_num] = nil unless player.play_again?
    end
  end

  def offer_seat(seat_num)
    puts "Would anyone like to take empty seat #{seat_num}?"
  end

  def clear_hands
    table.players.each do |player|
      next if player.nil?
      player.hands.clear
    end

    self.hand = nil
    table.hands_dealt = false
  end

  def grab_player_name
    prompt_for_name
    name = gets.chomp.strip
    capitalize_full_name(name)
  end

  def assign_seating(seat_num, new_player)
    table.seats[seat_num] = new_player
    new_player.table = table
  end

  def deal
    2.times do
      table.hands.each(&:hit)
    end

    table.hands_dealt = true
  end

  def take_bets
    table.players.each do |player|
      player.hands.each do |hand|
        table.refresh
        prompt_bet(player, hand)
        hand.bet
      end
    end
  end

  def deal_move(hand, move_choice)
    case move_choice
    when 'hit'
      hand.hit
    when 'stay'
      hand.stay
    when 'split'
      hand.split
    when 'double down'
      hand.double_down
    end
  end

  def settle_round
    move

    table.players.each do |player|
      player.hands.each do |hand|
        next if hand.bust?
        hand.settle
      end
    end
    table.display('reveal')
    sleep 3
  end

  private

  def prompt_for_name
    puts "Please enter a name or press Enter to skip"
    print "Name: "
  end

  def prompt_bet(player, hand)
    puts "\n#{player}, what would you like to bet?"
    hand.display_info
  end

  def choose_move
    if hand.value < 17
      'hit'
    else
      'stay'
    end
  end

  def move
    loop do
      move_choice = choose_move
      deal_move(hand, move_choice)
      break if hand.done?
    end
  end
end
