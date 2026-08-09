class TagsController < ApplicationController
  before_action :set_tag, only: %i[ show edit update destroy ]

  def index
    @tags = Current.user.tags.order(:name)
  end

  def show
    @captures = @tag.captures.order(created_at: :desc)
  end

  def new
    @tag = Current.user.tags.build
  end

  def edit
  end

  def create
    @tag = Current.user.tags.build(tag_params)

    if @tag.save
      redirect_to @tag, notice: "Tag created."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @tag.errors.add(:name, "has already been taken")
    render :new, status: :unprocessable_entity
  end

  def update
    if @tag.update(tag_params)
      redirect_to @tag, notice: "Tag updated."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @tag.errors.add(:name, "has already been taken")
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @tag.destroy!
    redirect_to tags_path, notice: "Tag deleted.", status: :see_other
  end

  private
    def set_tag
      @tag = Current.user.tags.find(params[:id])
    end

    def tag_params
      params.expect(tag: [ :name ])
    end
end
