# frozen_string_literal: true

# controller actions for Users
class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: %w[show edit update destroy]

  layout 'application'

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
      notify_success action: 'create', class_name: @user.class, identifier: @user.email
      redirect_to user_path(@user)
    else
      alert_failure action: 'create', class_name: @user.class, identifier: @user.email,
                    error: @user.errors.map(&:full_message).join(', ')
      render :new
    end
  end

  def update
    if @user.update(**user_params)
      notify_success action: 'update', class_name: @user.class, identifier: @user.email
      redirect_to user_path(@user)
    else
      alert_failure action: 'update', class_name: @user.class, identifier: @user.email,
                    error: @user.errors.map(&:full_message).join(', ')
      render :edit
    end
  end

  def destroy
    @user.destroy
    notify_success action: 'destroy', class_name: @user.class, identifier: @user.email
    redirect_to users_path
  rescue StandardError => e
    alert_failure action: 'destroy', class_name: @user.class, identifier: @user.slug,
                  error: e.message
    render :show
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
