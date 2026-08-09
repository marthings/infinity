class Capture < ApplicationRecord
  belongs_to :user

  has_many :collection_captures, dependent: :destroy
  has_many :collections, through: :collection_captures
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many_attached :uploads

  normalizes :source_url, :source_name, :title, :description, :note, with: ->(value) { value&.strip&.presence }

  validate :has_content
  validate :source_url_uses_http

  private
    def has_content
      return if source_url.present? || title.present? || description.present? || note.present? || uploads.attached?

      errors.add(:base, "Add a link, note, description, title, or upload")
    end

    def source_url_uses_http
      return if source_url.blank?

      uri = URI.parse(source_url)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:source_url, "must be an HTTP or HTTPS URL")
    rescue URI::InvalidURIError
      errors.add(:source_url, "must be an HTTP or HTTPS URL")
    end
end
