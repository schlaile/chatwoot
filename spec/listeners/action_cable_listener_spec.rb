require 'rails_helper'
describe ActionCableListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: agent) }

  before do
    create(:inbox_member, inbox: inbox, user: agent)
  end

  describe '#message_created' do
    let(:event_name) { :'message.created' }
    let!(:message) do
      create(:message, message_type: 'outgoing',
                       account: account, inbox: inbox, conversation: conversation)
    end
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)

      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [agent.pubsub_token, admin.pubsub_token, conversation.contact.pubsub_token], 'message.created', message.push_event_data
      )
      listener.message_created(event)
    end
  end

  describe '#typing_on' do
    let(:event_name) { :'conversation.typing_on' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [admin.pubsub_token, conversation.contact.pubsub_token],
        'conversation.typing_on', conversation: conversation.push_event_data,
                                  user: agent.push_event_data
      )
      listener.conversation_typing_on(event)
    end
  end

  describe '#typing_off' do
    let(:event_name) { :'conversation.typing_off' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, conversation: conversation, user: agent) }

    it 'sends message to account admins, inbox agents and the contact' do
      # HACK: to reload conversation inbox members
      expect(conversation.inbox.reload.inbox_members.count).to eq(1)
      expect(ActionCableBroadcastJob).to receive(:perform_later).with(
        [admin.pubsub_token, conversation.contact.pubsub_token],
        'conversation.typing_off', conversation: conversation.push_event_data,
                                   user: agent.push_event_data
      )
      listener.conversation_typing_off(event)
    end
  end
end
