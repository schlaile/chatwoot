# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let!(:user) { create(:user) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:name) }
  end

  context 'associations' do
    it { is_expected.to have_many(:accounts).through(:account_users) }
    it { is_expected.to have_many(:account_users) }
    it { is_expected.to have_many(:assigned_conversations).class_name('Conversation').dependent(:nullify) }
    it { is_expected.to have_many(:inbox_members).dependent(:destroy) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:messages) }
    it { is_expected.to have_many(:events) }
  end

  describe 'pubsub_token' do
    before { user.update(name: Faker::Name.name) }

    it { expect(user.pubsub_token).not_to eq(nil) }
    it { expect(user.saved_changes.keys).not_to eq('pubsub_token') }
  end
end
