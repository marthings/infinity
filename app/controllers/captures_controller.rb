class CapturesController < ApplicationController
  before_action :set_capture, only: %i[ show edit update destroy ]

  def index
    @capture = Current.user.captures.build
    @captures = Current.user.captures.order(created_at: :desc)
  end

  def show
  end

  def new
    @capture = Current.user.captures.build(source_url: params[:source_url].presence || params[:url].presence)
    load_organization
  end

  def share
    if share_params_missing?
      redirect_to new_capture_path
      return
    end

    @capture = Current.user.captures.build(source_url: shared_source_url)

    if @capture.save
      redirect_to @capture, notice: "Capture saved."
    else
      load_organization
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_organization
  end

  def create
    @capture = Current.user.captures.build(capture_params)

    if @capture.save
      redirect_to @capture, notice: "Capture saved."
    else
      if quick_capture?
        @captures = Current.user.captures.order(created_at: :desc)
        render :index, status: :unprocessable_entity
      else
        load_organization
        render :new, status: :unprocessable_entity
      end
    end
  end

  def update
    if @capture.update(capture_params)
      redirect_to @capture, notice: "Capture updated."
    else
      load_organization
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @capture.destroy!
    redirect_to captures_path, notice: "Capture deleted.", status: :see_other
  end

  private
    def set_capture
      @capture = Current.user.captures.find(params[:id])
    end

    def capture_params
      attributes = params.expect(capture: [ :source_url, :source_name, :title, :description, :note, :published_at, uploads: [], collection_ids: [], tag_ids: [] ])
      attributes[:collection_ids] = Current.user.collections.where(id: attributes[:collection_ids]).ids
      attributes[:tag_ids] = Current.user.tags.where(id: attributes[:tag_ids]).ids
      attributes
    end

    def load_organization
      @collections = Current.user.collections.order(:name)
      @tags = Current.user.tags.order(:name)
    end

    def quick_capture?
      params[:capture_form] == "quick"
    end

    def share_params_missing?
      params[:url].blank? && params[:source_url].blank? && params[:text].blank?
    end

    def shared_source_url
      explicit = params[:url].presence || params[:source_url].presence
      return explicit if explicit

      Capture.http_url_from(params[:text])
    end
end
