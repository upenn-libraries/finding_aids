# frozen_string_literal: true

# Actions for handling Legacy ID redirects
class LegacyController < ApplicationController
  before_action :init_solr

  def redirect
    id = @solr.find_id_by_legacy_id params[:id].to_s

    if id
      redirect_to solr_document_url(id), status: :permanent_redirect, notice: I18n.t('legacy.redirect')
    else
      head :not_found
    end
  end

  private

  def init_solr
    @solr = SolrService.new
  end
end
