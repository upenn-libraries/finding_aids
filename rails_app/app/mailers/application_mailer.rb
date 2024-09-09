# frozen_string_literal: true

# Base class for Mailers.
class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@library.upenn.edu'
  layout 'mailer'
end
