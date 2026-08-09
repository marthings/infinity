class ProfilesController < ApplicationController
  def show
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :show, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    @user.errors.add(:email_address, "has already been taken")
    render :show, status: :unprocessable_entity
  end

  private
    def profile_params
      attributes = params.expect(profile: [ :email_address, :password, :password_confirmation ])
      attributes[:password].blank? ? attributes.except(:password, :password_confirmation) : attributes
    end
end
