class ActionCableListener < BaseListener
  include Events::Types

  def conversation_created(event)
    conversation, account, timestamp = extract_conversation_and_account(event)

    broadcast(user_tokens(account, conversation.inbox.members), CONVERSATION_CREATED, conversation.push_event_data)
  end

  def conversation_read(event)
    conversation, account, timestamp = extract_conversation_and_account(event)

    broadcast(user_tokens(account, conversation.inbox.members), CONVERSATION_READ, conversation.push_event_data)
  end

  def message_created(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    tokens = user_tokens(account, conversation.inbox.members) + contact_token(conversation.contact, message)

    broadcast(tokens, MESSAGE_CREATED, message.push_event_data)
  end

  def message_updated(event)
    message, account, timestamp = extract_message_and_account(event)
    conversation = message.conversation
    contact = conversation.contact
    tokens = user_tokens(account, conversation.inbox.members) + contact_token(conversation.contact, message)

    broadcast(tokens, MESSAGE_UPDATED, message.push_event_data)
  end

  def conversation_resolved(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members) + [conversation.contact&.pubsub_token]

    broadcast(tokens, CONVERSATION_RESOLVED, conversation.push_event_data)
  end

  def conversation_opened(event)
    conversation, account, timestamp = extract_conversation_and_account(event)
    tokens = user_tokens(account, conversation.inbox.members) + [conversation.contact&.pubsub_token]

    broadcast(tokens, CONVERSATION_OPENED, conversation.push_event_data)
  end

  def conversation_lock_toggle(event)
    conversation, account, timestamp = extract_conversation_and_account(event)

    broadcast(user_tokens(account, conversation.inbox.members), CONVERSATION_LOCK_TOGGLE, conversation.lock_event_data)
  end

  def conversation_typing_on(event)
    conversation = event.data[:conversation]
    account = conversation.account
    user = event.data[:user]
    tokens = typing_event_listener_tokens(account, conversation, user)

    broadcast(
      tokens,
      CONVERSATION_TYPING_ON,
      conversation: conversation.push_event_data,
      user: user.push_event_data
    )
  end

  def conversation_typing_off(event)
    conversation = event.data[:conversation]
    account = conversation.account
    user = event.data[:user]
    tokens = typing_event_listener_tokens(account, conversation, user)

    broadcast(
      tokens,
      CONVERSATION_TYPING_OFF,
      conversation: conversation.push_event_data,
      user: user.push_event_data
    )
  end

  def assignee_changed(event)
    conversation, account, timestamp = extract_conversation_and_account(event)

    broadcast(user_tokens(account, conversation.inbox.members), ASSIGNEE_CHANGED, conversation.push_event_data)
  end

  def contact_created(event)
    contact, account, timestamp = extract_contact_and_account(event)

    broadcast(user_tokens(account, account.agents), CONTACT_CREATED, contact.push_event_data)
  end

  def contact_updated(event)
    contact, account, timestamp = extract_contact_and_account(event)

    broadcast(user_tokens(account, account.agents), CONTACT_UPDATED, contact.push_event_data)
  end

  private

  def typing_event_listener_tokens(account, conversation, user)
    (user_tokens(account, conversation.inbox.members) + [conversation.contact.pubsub_token]) - [user&.pubsub_token]
  end

  def user_tokens(account, agents)
    agent_tokens = agents.pluck(:pubsub_token)
    admin_tokens = account.administrators.pluck(:pubsub_token)
    pubsub_tokens = (agent_tokens + admin_tokens).uniq
    pubsub_tokens
  end

  def contact_token(contact, message)
    return [] if message.private?
    return [] if message.activity?
    return [] if contact.nil?

    [contact.pubsub_token]
  end

  def broadcast(tokens, event_name, data)
    return if tokens.blank?

    ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, data)
  end
end
