# frozen_string_literal: true

# Admin CRUD for featured collections shown on the homepage.
class FeaturedCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_guide, only: %i[edit update destroy]
  before_action :load_form_data, only: %i[new create edit update]

  layout 'application'

  def index
    @guides = FeaturedCollection.order(created_at: :desc)
  end

  def new
    @guide = FeaturedCollection.new
  end

  def edit; end

  def create
    @guide = FeaturedCollection.new(guide_params)
    persist(:create, :new)
  end

  def update
    @guide.assign_attributes(guide_params)
    persist(:update, :edit)
  end

  def destroy
    @guide.destroy
    notify_success action: :destroy, class_name: FeaturedCollection.model_name.human, identifier: @guide.title
    redirect_to featured_collections_path
  end

  private

  def find_guide
    @guide = FeaturedCollection.find(params[:id])
  end

  def load_form_data
    @titles_by_repository = RepositoryQueries.titles_by_repository
    ensure_current_record_titles
    @repositories = @titles_by_repository.keys.sort
  rescue StandardError => e
    Rails.logger.warn "FeaturedCollectionsController: failed to load form data - #{e.class}: #{e.message}"
    @titles_by_repository = { @guide&.repository => [@guide&.title].compact }.compact
    @repositories = [@guide&.repository].compact
  end

  def persist(action, failure_view)
    if @guide.save
      notify_success action: action, class_name: FeaturedCollection.model_name.human, identifier: @guide.title
      redirect_to featured_collections_path
    else
      alert_failure action: action, class_name: FeaturedCollection.model_name.human,
                    identifier: @guide.title, error: @guide.errors.map(&:full_message).join(', ')
      render failure_view, status: :unprocessable_entity
    end
  end

  def ensure_current_record_titles
    return if @guide&.repository.blank?
    return if @guide.title.blank?

    titles = @titles_by_repository[@guide.repository] ||= []
    return if titles.include?(@guide.title)

    titles << @guide.title
    titles.sort!
  end

  def guide_params
    params.require(:featured_collection).permit(:title, :repository)
  end
end
