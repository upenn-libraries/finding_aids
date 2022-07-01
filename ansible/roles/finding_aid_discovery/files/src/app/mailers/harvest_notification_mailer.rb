# frozen_string_literal: true

class HarvestNotificationMailer < ApplicationMailer
  before_action { @endpoint = params[:endpoint] }

  FRIENDLY_PENN_PACSCL_CONTACT = 'hmengel@pobox.upenn.edu'

  default to: -> { @endpoint.tech_contacts },
          cc: FRIENDLY_PENN_PACSCL_CONTACT

  def complete_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} completed successfully")
  end

  def partial_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} partially completed")
  end

  def failed_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} failed")
  end
end
