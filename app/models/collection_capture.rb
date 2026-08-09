class CollectionCapture < ApplicationRecord
  belongs_to :capture
  belongs_to :collection

  before_validation :place_at_end, on: :create

  validates :capture_id, uniqueness: { scope: :collection_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, uniqueness: { scope: :collection_id }
  validate :capture_belongs_to_collection_user

  private
    def place_at_end
      self.position ||= collection.collection_captures.maximum(:position).to_i + 1 if collection
    end

    def capture_belongs_to_collection_user
      return unless capture && collection
      return if capture.user_id == collection.user_id

      errors.add(:capture, "must belong to the collection owner")
    end
end
