class Hand
  attr_reader :cards
  attr_accessor :bet_amount, :status, :owner, :table

  MOVES = ['hit', 'stay', 'split', 'double down']

  def initialize
    @cards = []
    @bet_amount = nil
    @status = nil
    @owner = nil
    @table = nil
  end

  def done?
    ['stay', 'bust'].include?(status)
  end

  def hit
    cards << table.deck.draw

    return unless bust?
    self.status = 'bust'
    owner.chips -= bet_amount unless owner == table.dealer
  end

  def bust?
    value > 21
  end

  def settle
    if win?
      self.status = 'win'
      owner.chips += bet_amount
    elsif tied?
      self.status = 'tie'
    else
      self.status = 'lose'
      owner.chips -= bet_amount
    end
  end

  def bet
    bet_amount = grab_bet
    self.bet_amount = bet_amount.to_i
  end

  def valid_move?(move)
    if move == 'split'
      splittable?
    elsif move == 'double down'
      owner.enough_chips?(bet_amount * 2)
    elsif !MOVES.include?(move)
      puts 'Invalid move. Please try again.'
      false
    else
      true
    end
  end

  def stay
    self.status = 'stay'
  end

  def split
    owner.hands.clear
    owner.hands << split_hands
    owner.hands.flatten!
  end

  def double_down
    self.bet_amount *= 2
    self.status = 'stay'
    hit
  end

  def value
    sum = 0
    sorted_symbols = sort_card_value_syms

    sorted_symbols.each do |symbol|
      sum += card_value(symbol, sum)
    end
    sum
  end

  def to_s
    cards.to_s
  end

  def inspect
    cards.to_s
  end

  def display_info
    puts "Hand: #{cards}"
    puts "Amount of chips: #{owner.chips}"
  end

  private

  def win?
    if table.dealer.hand.bust?
      true
    else
      table.dealer.hand.value < value
    end
  end

  def tied?
    table.dealer.hand.value == value
  end

  def grab_bet
    loop do
      print "\nBet: "
      bet = gets.chomp.strip
      return bet if valid_bet_input?(bet) && owner.enough_chips?(bet)
      puts "Please try again."
      table.refresh
      display_info
    end
  end

  def split_hands
    cards.each_with_object([]) do |card, new_hands|
      new_hand = Hand.new
      new_hand.bet_amount = bet_amount / 2
      new_hand.table = table
      new_hand.owner = owner
      new_hand.cards << card
      new_hand.hit
      new_hands << new_hand
    end
  end

  def splittable?
    if cards.size > 2 || card_value_syms[0] != card_value_syms[1]
      puts "\n=> This hand is not splittable!"
      false
    elsif owner.hands.size >= 2
      puts "\n=> You can only split once."
      false
    else
      true
    end
  end

  def card_value_syms
    cards.each_with_object([]) do |card, card_nums|
      card_nums << card.scan(/(\d+|\w)/)
    end.flatten
  end

  def sort_card_value_syms
    # Value of aces determined last
    card_value_syms.partition { |value| value != 'A' }.flatten
  end

  def card_value(symbol, sum = 0)
    if ['J', 'Q', 'K'].include?(symbol)
      10
    elsif symbol == 'A'
      (sum + 11) <= 21 ? 11 : 1
    else
      symbol.to_i
    end
  end

  def valid_bet_input?(input)
    case input
    when /^\d+\.\d*$/
      puts 'Please enter in a whole number.'
    when /[a-zA-Z]/
      puts "\n=> Invalid input!"
    when 0, ''
      puts "\n=> You have to bet something"
    else
      true
    end
  end
end
