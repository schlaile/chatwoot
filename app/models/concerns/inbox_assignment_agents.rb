# frozen_string_literal: true

module InboxAssignmentAgents
  extend ActiveSupport::Concern

  # A cross-inbox assignment grants the selected agent access only to the
  # conversation being handed over. It never makes that agent a member of this
  # inbox, so new-conversation notifications and access to its other
  # conversations stay unchanged.
  def assignment_agents
    return assignable_agents unless allow_cross_inbox_assignment?

    account.users.to_a
  end

  def agent_assignable_to_conversation?(agent)
    agent.present? && agent.confirmed? && assignment_agents.include?(agent)
  end
end
