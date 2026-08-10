# frozen_string_literal: true

# Admin CRUD for featured collections shown on the homepage.
class FeaturedCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_guide, only: %i[destroy]

  layout 'application'

  def index
    @guides = FeaturedCollection.all
  end

  def new
    @guide = FeaturedCollection.new
  end

  def create
    @guide = FeaturedCollection.new
    data = RepositoryQueries.featured_collection_data_for(record_id: guide_params[:record_id])
    return create_failure(t('admin.featured_collections.messages.not_found')) if data.blank?

    @guide.assign_attributes(record_id: guide_params[:record_id], **data)
    return create_success if @guide.save

    create_failure(@guide.errors.full_messages)
    render :new, status: :unprocessable_content
  end

  def destroy
    @guide.destroy
    flash.notice = t('admin.featured_collections.messages.removed')
    redirect_to featured_collections_path
  end

  private

  def find_guide
    @guide = FeaturedCollection.find(params[:id])
  end

  def guide_params
    params.require(:featured_collection).permit(:record_id)
  end

  def create_success
    flash.notice = t('admin.featured_collections.messages.added')
    redirect_to featured_collections_path
  end

  def create_failure(message)
    flash.alert = message
    render :new, status: :unprocessable_content
  end
end
