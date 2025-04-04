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
  validates :active, inclusion: [true, false]

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_saml(auth)
    user = find_by(provider: auth.provider, uid: auth.info.uid.gsub('@upenn.edu', ''))
    return unless user

    user.email = auth.info.uid # update email with value from IdP, save will occur later
    user
  end

  # @param [OmniAuth::AuthHash] auth
  # @return [User, nil]
  def self.from_omniauth_developer(auth)
    return unless Rails.env.development?

    email = "#{auth.uid}@upenn.edu"
    where(provider: auth.provider, uid: auth.uid, active: true).first_or_create do |user|
      user.uid = auth.uid
      user.email = email
      user.active = true
    end
  end

  private

  # @return [TrueClass, FalseClass]
  def provider_provided?
    provider.present?
  end
end
