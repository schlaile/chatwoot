require 'rails_helper'

describe  ::Messages::Facebook::MessageBuilder do
  subject(:message_builder) { described_class.new(incoming_fb_text_message, facebook_channel.inbox).perform }

  let!(:facebook_channel) { create(:channel_facebook_page) }
  let!(:message_object) { JSON.parse(build(:incoming_fb_text_message).to_json, object_class: OpenStruct) }
  let!(:incoming_fb_text_message) { Integrations::Facebook::MessageParser.new(message_object) }
  let(:fb_object) { double }

  before do
    allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
    allow(fb_object).to receive(:get_object).and_return(
      {
        first_name: 'Jane',
        last_name: 'Dae',
        account_id: facebook_channel.inbox.account_id,
        profile_pic: 'https://via.placeholder.com/250x250.png'
      }.with_indifferent_access
    )
  end

  describe '#perform' do
    it 'creates contact and message for the facebook inbox' do
      message_builder

      contact = facebook_channel.inbox.contacts.first
      message = facebook_channel.inbox.messages.first

      expect(contact.name).to eq('Jane Dae')
      expect(message.content).to eq('facebook message')
    end
  end
end
