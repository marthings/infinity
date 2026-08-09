class Tagging < ApplicationRecord
  belongs_to :capture
  belongs_to :tag

  validates :capture_id, uniqueness: { scope: :tag_id }
  validate :capture_belongs_to_tag_user

  private
    def capture_belongs_to_tag_user
      return unless capture && tag
      return if capture.user_id == tag.user_id

      errors.add(:capture, "must belong to the tag owner")
    end
end
