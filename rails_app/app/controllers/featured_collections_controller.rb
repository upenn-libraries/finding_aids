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

    if @collection.save
      notify_success action: :create, class_name: 'Featured collection', identifier: @collection.title
      redirect_to featured_collections_path
    else
      alert_failure action: :create, class_name: 'Featured collection',
                    identifier: @collection.title, error: @collection.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @collection.update(collection_params)
      notify_success action: :update, class_name: 'Featured collection', identifier: @collection.title
      redirect_to featured_collections_path
    else
      alert_failure action: :update, class_name: 'Featured collection',
                    identifier: @collection.title, error: @collection.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    notify_success action: :destroy, class_name: 'Featured collection', identifier: @collection.title
    redirect_to featured_collections_path
  end

  def reorder
    params[:ids].each_with_index do |id, index|
      FeaturedCollection.where(id: id).update_all(position: index)
    end
    head :ok
  end

  private

  def find_collection
    @collection = FeaturedCollection.find(params[:id])
  end

  def load_form_data
    @titles_by_repository = RepositoryQueries.titles_by_repository

    # Ensure the current record's values are present even if stale
    if @collection&.repository.present?
      @titles_by_repository[@collection.repository] ||= []
      if @collection.title.present? && !@titles_by_repository[@collection.repository].include?(@collection.title)
        @titles_by_repository[@collection.repository] << @collection.title
        @titles_by_repository[@collection.repository].sort!
      end
    end

    @repositories = @titles_by_repository.keys.sort
  rescue StandardError => e
    Rails.logger.warn "FeaturedCollectionsController: failed to load form data — #{e.class}: #{e.message}"
    @titles_by_repository = { @collection&.repository => [@collection&.title].compact }.compact
    @repositories = [@collection&.repository].compact
  end

  def collection_params
    params.require(:featured_collection).permit(:title, :repository, :active)
  end
end
