# frozen_string_literal: true

describe User do
  it 'requires an email' do
    user = described_class.new email: nil
    expect(user.valid?).to be false
    expect(user.errors['email']).to include "can't be blank"
  end

  it 'requires a unique email per provider' do
    create(:user, email: 'test@upenn.edu')
    user = build(:user, email: 'test@upenn.edu')
    expect(user.valid?).to be false
    expect(user.errors['email']).to include 'has already been taken'
  end

  it 'requires a unique set of omniauth fields' do
    create(:user, email: 'test@upenn.edu', provider: 'developer', uid: 'test')
    user = build(:user, email: 'more@upenn.edu', provider: 'developer', uid: 'test')
    expect(user.valid?).to be false
    expect(user.errors['uid']).to include 'has already been taken'
  end

  it 'is active by default' do
    user = build(:user)
    expect(user.active).to be true
  end

  it 'requires a valid active status' do
    user = build(:user, active: nil)
    expect(user.valid?).to be false
    expect(user.errors['active']).to include 'is not included in the list'
  end
end
