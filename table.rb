require './deck'
require './hand'
require './participant'
require 'pry'
require 'pry-nav'

class Table
  attr_reader :seats
  attr_accessor :dealer

  def initialize
    @dealer = nil
    @seats = (1..num_seats).zip([nil] * num_seats).to_h
  end

  def start
    assign_dealer
    populate_seats

    loop do
      play_round
      populate_seats if add_more_players?
      break if empty?
    end
    display_goodbye
  end

  def refresh
    sleep 0.5
    system 'clear'
    display
  end

  def players
    seats.values.compact
  end

  def participants
    players << dealer
  end

  private

  def empty?
    players.all?(&:nil?)
  end

  def display_goodbye
    puts "There are no players. Goodbye. :("
    sleep 0.7
    system 'clear'
  end

  def assign_dealer
    name = ['David', 'Mark', 'Joe'].sample
    self.dealer = Dealer.new(name)
    dealer.table = self
  end

  def populate_seats
    seats.each do |seat_num, player|
      refresh
      if player.nil?
        refresh
        add_player(seat_num)
      end
    end
  end

  def add_player(seat_num)
    dealer.offer_seat(seat_num)
    name = dealer.grab_player_name
    return if name.empty?
    new_player = Player.new(name)
    dealer.assign_seating(seat_num, new_player)
  end

  def add_more_players?
    answer = nil

    loop do
      puts 'Add more players? (y/n)'
      answer = gets.chomp.strip.downcase
      break if ['y', 'n'].include?(answer)
      puts 'Invalid input. Please try again.'
    end
    answer == 'y'
  end
end

class BlackjackTable < Table
  attr_accessor :deck, :hands_dealt

  NUM_SEATS = 4
  @@num_tables = 0

  def initialize
    super()
    add_deck
    @hands_dealt = false
    @@num_tables += 1
  end

  def seat_length
    hands_dealt ? (longest_hand + 2) : 15
  end

  def hands
    players.map(&:hands).flatten << dealer.hand
  end

  def display(dealer_first_card = 'hidden')
    return if too_large?
    puts "Move options: #{Hand::MOVES.join(', ')}".center(length)
    display_label
    display_border
    display_dealer(dealer_first_card)
    display_border
    display_players
    display_border
  end

  protected

  def num_seats
    NUM_SEATS
  end

  private

  def make_moves
    loop do
      players.each(&:move)
      break if players.all?(&:done?)
    end
  end

  def too_large?
    if length > 150
      puts "Table too large to display.\n"
      true
    else
      false
    end
  end

  def add_dealer_hand
    new_hand = Hand.new
    new_hand.table = self
    new_hand.owner = dealer
    dealer.hand = new_hand
  end

  def add_player_hands
    players.each do |player|
      new_hand = Hand.new
      new_hand.table = self
      new_hand.owner = player
      player.hands << new_hand
    end
  end

  def add_deck
    @deck = Deck.new
    deck.table = self
  end

  alias replace_deck add_deck

  def length
    seat_length * num_seats
  end

  def add_hands
    add_player_hands
    add_dealer_hand
  end

  def play_round
    add_hands
    dealer.deal
    dealer.take_bets
    make_moves
    dealer.settle_round
    dealer.remove_broke_players
    dealer.clear_hands
    dealer.prompt_another_round
  end

  def longest_hand
    max_length = 0

    players.each do |player|
      hands_length = player.hands.to_s.length
      max_length = hands_length if hands_length > max_length
    end

    max_length
  end

  def display_label
    puts ''
    puts "Blackjack Table #{@@num_tables}".center((length) + num_seats)
  end

  def display_border
    puts '-' * length
  end

  def display_dealer(dealer_first_card)
    puts "Dealer".center((seat_length * num_seats) + num_seats)

    if dealer.nil?
      2.times do
        puts ' '.center((length) + num_seats)
      end
    else
      display_dealer_name
      display_dealer_hand(dealer_first_card)
    end
  end

  def display_dealer_name
    puts dealer.name.center((length) + num_seats)
  end

  def display_dealer_hand(first_card)
    hand = if first_card == 'reveal'
             dealer.hand
           elsif dealer.hand.nil?
             ' '
           else
             ['[]', dealer.hand.cards[1..-1]].flatten.to_s
           end

    puts hand.to_s.center(length + 3)
  end

  def display_players
    display_player_outcomes
    display_player_bets
    display_player_hands
    display_player_names
    display_player_chips
  end

  def display_player_outcomes
    player_outcomes = seats.values.map do |player|
      if player.nil?
        ' ' * seat_length
      else
        player.combine_statuses.center(seat_length)
      end
    end

    puts player_outcomes.join('|')
  end

  def display_player_bets
    player_bets = seats.values.map do |player|
      if player.nil?
        ' ' * seat_length
      else
        player.combine_bets.center(seat_length)
      end
    end

    puts player_bets.join('|')
  end

  def display_player_hands
    player_hands = seats.values.map do |player|
      if player.nil?
        ' ' * seat_length
      else
        player.combined_hands.center(seat_length)
      end
    end
    puts player_hands.join('|')
  end

  def display_player_chips
    player_chips = seats.values.map do |player|
      if player.nil?
        ' '.center(seat_length)
      else
        "Chips: #{player.chips}".center(seat_length)
      end
    end

    puts player_chips.join('|')
  end

  def display_player_names
    player_names = seats.values.map do |player|
      if player.nil?
        ' ' * seat_length
      else
        player.centered_name(seat_length)
      end
    end

    puts player_names.join('|')
  end
end
