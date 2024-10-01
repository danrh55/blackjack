class Deck
  attr_accessor :cards, :table

  NUM_PACKS = 4
  CARD_NUMS = ('2'..'10').to_a + ['A', 'J', 'Q', 'K']
  SUITES = { Heart: "\u{2661}",
             Diamond: "\u{25C7}",
             Spade: "\u{2660}",
             Club: "\u{2667}" }

  def initialize
    @cards = shuffle(new_cards * NUM_PACKS)
    @table = nil
  end

  def empty?
    cards.empty?
  end

  def draw
    drawn_card = cards.pop
    table.replace_deck if table.deck.empty?
    drawn_card
  end

  private

  def new_cards
    SUITES.values.each_with_object([]) do |suite, deck_arr|
      CARD_NUMS.each do |card_num|
        deck_arr.push(card_num + suite)
      end
    end
  end

  def to_s
    cards.to_s
  end

  def shuffle(cards)
    shuffled_deck = []

    until cards.empty?
      shuffled_deck.push(cards.delete(cards.sample))
    end

    shuffled_deck
  end
end
