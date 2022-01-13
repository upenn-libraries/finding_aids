class HarvestNotificationMailer < ApplicationMailer
  before_action { @endpoint = params[:endpoint] }

  default to: -> { @endpoint.tech_contacts }

  def complete_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} completed successful")
  end

  def partial_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} partially completed")
  end

  def failed_harvest_notification
    mail(subject: "Harvest of #{@endpoint.slug} failed")
  end
end