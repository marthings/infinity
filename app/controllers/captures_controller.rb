class CapturesController < ApplicationController
  before_action :set_capture, only: %i[ show edit update destroy ]

  def index
    @captures = Current.user.captures.order(created_at: :desc)
  end

  def show
  end

  def new
    @capture = Current.user.captures.build
  end

  def edit
  end

  def create
    @capture = Current.user.captures.build(capture_params)

    if @capture.save
      redirect_to @capture, notice: "Capture saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @capture.update(capture_params)
      redirect_to @capture, notice: "Capture updated."
    else
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
      params.expect(capture: [ :source_url, :source_name, :title, :description, :note, :published_at, uploads: [] ])
    end
end
