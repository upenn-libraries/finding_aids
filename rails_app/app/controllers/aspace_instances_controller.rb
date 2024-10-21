# frozen_string_literal: true

# controller actions for ASpaceInstances
class ASpaceInstancesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_aspace_instance, only: %w[show edit update destroy]

  layout 'application'

  def index
    @aspace_instances = ASpaceInstance.page(params[:page])
  end

  def show; end

  def new
    @aspace_instance = ASpaceInstance.new
  end

  def edit; end

  def create
    @aspace_instance = ASpaceInstance.new(aspace_instance_params)
    if @aspace_instance.save
      notify_success action: :create, class_name: @aspace_instance.class, identifier: @aspace_instance.slug
      redirect_to aspace_instance_path(@aspace_instance)
    else
      alert_failure action: :create, class_name: @aspace_instance.class, identifier: @aspace_instance.slug,
                    error: @aspace_instance.errors.map(&:full_message).join(', ')
      render :new
    end
  end

  def update
    if @aspace_instance.update(aspace_instance_params.except(:slug))
      notify_success action: :update, class_name: @aspace_instance.class, identifier: @aspace_instance.slug
      redirect_to aspace_instance_path(@aspace_instance)
    else
      alert_failure action: :update, class_name: @aspace_instance.class, identifier: @aspace_instance.slug,
                    error: @aspace_instance.errors.map(&:full_message).join(', ')
      render :edit
    end
  end

  def destroy
    @aspace_instance.destroy
    notify_success action: :destroy, class_name: @aspace_instance.class, identifier: @aspace_instance.slug
    redirect_to aspace_instances_path
  rescue StandardError => e
    alert_failure action: :destroy, class_name: @aspace_instance.class, identifier: @aspace_instance.slug,
                  error: e.message
    render :show
  end

  private

  # @return [ASpaceInstance]
  def load_aspace_instance
    @aspace_instance = ASpaceInstance.find params[:id]
  end

  # @return [ActionController::Parameters]
  def aspace_instance_params
    params.require(:aspace_instance).permit(:slug, :base_url)
  end
end
