# frozen_string_literal: true

# AR model of a user that manages data on the application, configured to be authenticated
# with devise and omniauth
class User < ApplicationRecord
  devise :timeoutable
  if Rails.env.development?
    devise :omniauthable, omniauth_providers: %i[developer saml]
  else
    devise :omniauthable, omniauth_providers: %i[saml]
  end

  validates :email, presence: true, uniqueness: true
  validates :uid, uniqueness: { scope: :provider }, if: :provider_provided?

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.active = true
    end
  end

  private

  # @return [TrueClass, FalseClass]
  def provider_provided?
    provider.present?
  end
end
