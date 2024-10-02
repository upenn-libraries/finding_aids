# frozen_string_literal: true

# controller actions for Users
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: %w[show edit update destroy]

  def index
    @users = User.page(params[:page])
  end

  def show; end

  def new
    @user = User.new
  end

  def edit; end

  def create
    @user = User.new(**user_params, provider: 'saml')
    if @user.save
      flash.notice = "User access granted for #{@user.uid}"
      redirect_to user_path(@user)
    else
      flash.alert = "Problem adding user: #{@user.errors.map(&:full_message).join(', ')}"
      render :new
    end
  end

  def update
    @user.update(**user_params)
    if @user.save
      flash.notice = 'User successfully updated'
      redirect_to user_path(@user)
    else
      flash.alert = "Problem updating user: #{@user.errors.map(&:full_message).join(', ')}"
      render :edit
    end
  end

  def destroy
    if @user.destroy
      flash.notice = 'User has been deleted'
      redirect_to users_path
    else
      flash.alert = "User could not be deleted: #{@user.errors.map(&:full_message).join(', ')}"
    end
  end

  private

  # @return [User]
  def load_user
    @user = User.find params[:id]
  end

  # @return [ActionController::Parameters]
  def user_params
    params.require(:user).permit(:uid, :email, :active).tap do |p|
      p[:email] = "#{p[:uid]}@upenn.edu" if p[:email].blank?
    end
  end
end
