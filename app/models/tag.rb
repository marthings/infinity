class Tag < ApplicationRecord
  belongs_to :user

  has_many :taggings, dependent: :destroy
  has_many :captures, through: :taggings

  normalizes :name, with: ->(value) { value&.strip&.downcase&.presence }
  validates :name, presence: true, uniqueness: { scope: :user_id }
end
