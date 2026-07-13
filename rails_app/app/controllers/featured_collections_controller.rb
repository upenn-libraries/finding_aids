# frozen_string_literal: true

# Admin CRUD for featured collections shown on the homepage.
class FeaturedCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_guide, only: %i[destroy]
  before_action :load_form_data, only: %i[new create]

  layout 'application'

  def index
    @guides = FeaturedCollection.order(created_at: :desc)
  end

  def new
    @guide = FeaturedCollection.new
  end

  def create
    @guide = FeaturedCollection.new(guide_params)

    if @guide.save
      flash.notice = I18n.t('admin.flash.create.success',
                            class_name: FeaturedCollection.model_name.human,
                            identifier: @guide.title)
      redirect_to featured_collections_path
    else
      flash.alert = I18n.t('admin.flash.create.failure',
                           class_name: FeaturedCollection.model_name.human,
                           identifier: @guide.title,
                           error: @guide.errors.map(&:full_message).join(', '))
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @guide.destroy
    flash.notice = I18n.t('admin.flash.destroy.success',
                          class_name: FeaturedCollection.model_name.human,
                          identifier: @guide.title)
    redirect_to featured_collections_path
  end

  private

  def find_guide
    @guide = FeaturedCollection.find(params[:id])
  end

  def load_form_data
    @titles_by_repository = RepositoryQueries.titles_by_repository
    @repositories = @titles_by_repository.keys.sort
  rescue StandardError => e
    Rails.logger.warn "FeaturedCollectionsController: failed to load form data - #{e.class}: #{e.message}"
    @titles_by_repository = {}
    @repositories = []
  end

  def guide_params
    params.require(:featured_collection).permit(:title, :repository)
  end
end
