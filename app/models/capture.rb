class Capture < ApplicationRecord
  belongs_to :user

  has_many :collection_captures, dependent: :destroy
  has_many :collections, through: :collection_captures
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings
  has_many_attached :uploads

  normalizes :source_url, :source_name, :title, :description, :note, with: ->(value) { value&.strip&.presence }

  before_validation :generate_title, on: :create
  after_create_commit :enrich_link_preview_later, if: :link?
  after_update_commit :enrich_link_preview_later, if: :saved_change_to_source_url?
  after_update_commit :broadcast_inbox_preview, if: :saved_change_to_preview?

  validate :has_content
  validate :source_url_uses_http

  def enrich_link_preview
    apply_link_preview(Capture::LinkPreview.fetch(source_url))
  rescue Capture::LinkPreview::UnsafeUrl, Capture::LinkPreview::UnsupportedResponse
    nil
  end

  def apply_link_preview(preview)
    return unless preview

    attributes = {}
    attributes[:source_name] = preview.source_name if source_name.blank? && preview.source_name.present?
    attributes[:title] = preview.title if title == title_from_source_url && preview.title.present?
    attributes[:description] = preview.description if description.blank? && preview.description.present?

    update!(attributes) if attributes.any?
  end

  private
    def enrich_link_preview_later
      EnrichCaptureLinkJob.perform_later(self)
    end

    def broadcast_inbox_preview
      broadcast_replace_later_to [ user, :captures ],
        target: ActionView::RecordIdentifier.dom_id(self),
        partial: "captures/capture",
        locals: { capture: self }
    end

    def generate_title
      self.title ||= title_from_source_url || title_from_upload
    end

    def link?
      source_url.present?
    end

    def saved_change_to_preview?
      saved_change_to_source_name? || saved_change_to_title? || saved_change_to_description?
    end

    def title_from_source_url
      URI.parse(source_url).host&.delete_prefix("www.")&.downcase
    rescue URI::InvalidURIError
      nil
    end

    def title_from_upload
      uploads.first&.filename&.to_s
    end

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
