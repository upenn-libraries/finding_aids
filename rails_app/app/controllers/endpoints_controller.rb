# frozen_string_literal: true

# controller actions for Endpoints
class EndpointsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_endpoint, only: %w[show edit update harvest]
  before_action :load_aspace_instances, only: %w[new create edit update]

  layout 'application'

  def index
    @endpoints = Endpoint.page(params[:page])
  end

  def show; end

  def new
    @endpoint = Endpoint.new
  end

  def edit; end

  def create
    @endpoint = Endpoint.new(endpoint_params)
    if @endpoint.save
      notify_success action: :create, class_name: @endpoint.class, identifier: @endpoint.slug
      redirect_to endpoint_path(@endpoint)
    else
      alert_failure action: :create, class_name: @endpoint.class, identifier: @endpoint.slug,
                    error: @endpoint.errors.map(&:full_message).join(', ')
      render :new
    end
  end

  def update
    if @endpoint.update(endpoint_params.except(:slug))
      notify_success action: :update, class_name: @endpoint.class, identifier: @endpoint.slug
      redirect_to endpoint_path(@endpoint)
    else
      alert_failure action: :update, class_name: @endpoint.class, identifier: @endpoint.slug,
                    error: @endpoint.errors.map(&:full_message).join(', ')
      render :edit
    end
  end

  def destroy; end

  def harvest
    PartnerHarvestJob.perform_later @endpoint
    notify_success action: :harvest, class_name: @endpoint.class.name, identifier: @endpoint.slug
    redirect_to endpoint_path(@endpoint)
  rescue StandardError => e
    alert_failure action: :harvest, class_name: @endpoint.class.name, identifier: @endpoint.slug,
                  error: e.message
    redirect_to endpoint_path(@endpoint)
  end

  private

  def load_endpoint
    @endpoint = Endpoint.find(params[:id])
  end

  def load_aspace_instances
    @aspace_instances = ASpaceInstance.all
  end

  # @return [ActionController::Parameters]
  def endpoint_params
    prepare_contacts_params
    params.require(:endpoint).permit(:slug, { public_contacts: [] }, { tech_contacts: [] }, :source_type, :webpage_url,
                                     :aspace_repo_id, :aspace_instance_id, :active)
  end

  # @return [ActionController::Parameters]
  def prepare_contacts_params
    params[:endpoint][:public_contacts] = params[:endpoint][:public_contacts].split(',').map(&:strip)
    params[:endpoint][:tech_contacts] = params[:endpoint][:tech_contacts].split(',').map(&:strip)
  end
end
