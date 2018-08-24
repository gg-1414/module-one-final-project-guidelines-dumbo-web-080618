require 'pry'
class Card < ActiveRecord::Base
  has_many :reading_cards
  has_many :users, through: :reading_cards

  def self.love_cards
    Card.all.select do |c|
      c.category == "love"
    end
  end

  def self.future_cards
    Card.all.select do |c|
      c.category == "future"
    end
  end

  def self.career_cards
    Card.all.select do |c|
      c.category == "career"
    end
  end

  def self.self_cards
    Card.all.select do |c|
      c.category == "self"
    end
  end

  def try_img(num)
    Catpix::print_image "img/image_#{num}.png",
    :limit_x => 0.5,
    :limit_y => 0.9,
    :center_x => true,
    :center_y => false,
    :bg => "black",
    :bg_fill => true,
    :resolution => "high"
  end

  def card_img
    Card.all.find do |e|
      if e.id == self.id
        try_img(Random.rand(1..11))
      end
    end
  end

end
