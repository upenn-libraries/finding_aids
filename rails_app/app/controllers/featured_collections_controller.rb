# frozen_string_literal: true

# Admin CRUD for featured collections shown on the homepage.
class FeaturedCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_collection, only: %i[edit update destroy]
  before_action :load_form_data, only: %i[new create edit update]

  layout 'application'

  def index
    @collections = FeaturedCollection.order(:position)
  end

  def new
    @collection = FeaturedCollection.new
  end

  def edit; end

  def create
    @collection = FeaturedCollection.new(collection_params)
    @collection.position = FeaturedCollection.maximum(:position).to_i + 1
    persist(:create, :new)
  end

  def update
    @collection.assign_attributes(collection_params)
    persist(:update, :edit)
  end

  def destroy
    @collection.destroy
    notify_success action: :destroy, class_name: FeaturedCollection.model_name.human, identifier: @collection.title
    redirect_to featured_collections_path
  end

  def reorder
    params[:ids].each_with_index do |id, index|
      FeaturedCollection.find(id).update!(position: index)
    end
    head :ok
  end

  private

  def find_collection
    @collection = FeaturedCollection.find(params[:id])
  end

  def load_form_data
    @titles_by_repository = RepositoryQueries.titles_by_repository
    ensure_current_record_titles
    @repositories = @titles_by_repository.keys.sort
  rescue StandardError => e
    Rails.logger.warn "FeaturedCollectionsController: failed to load form data — #{e.class}: #{e.message}"
    @titles_by_repository = { @collection&.repository => [@collection&.title].compact }.compact
    @repositories = [@collection&.repository].compact
  end

  def persist(action, failure_view)
    if @collection.save
      notify_success action: action, class_name: FeaturedCollection.model_name.human, identifier: @collection.title
      redirect_to featured_collections_path
    else
      alert_failure action: action, class_name: FeaturedCollection.model_name.human,
                    identifier: @collection.title, error: @collection.errors.map(&:full_message).join(', ')
      render failure_view, status: :unprocessable_entity
    end
  end

  def ensure_current_record_titles
    return if @collection&.repository.blank? || @collection.title.blank?

    titles = @titles_by_repository[@collection.repository] ||= []
    return if titles.include?(@collection.title)

    titles << @collection.title
    titles.sort!
  end

  def collection_params
    params.require(:featured_collection).permit(:title, :repository, :active)
  end
end
