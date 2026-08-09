class Collection < ApplicationRecord
  belongs_to :user

  has_many :collection_captures, -> { order(:position) }, dependent: :destroy
  has_many :captures, -> { order(CollectionCapture.arel_table[:position]) }, through: :collection_captures

  normalizes :name, with: ->(value) { value&.strip&.presence }
  validates :name, presence: true
end
