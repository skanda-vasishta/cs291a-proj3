module ConversationPresenter
  extend ActiveSupport::Concern

  private

  def conversation_payload(conversation, viewer:)
    {
      id: conversation.id.to_s,
      title: conversation.title,
      status: conversation.status,
      questionerId: conversation.initiator_id.to_s,
      questionerUsername: conversation.initiator.username,
      assignedExpertId: conversation.assigned_expert_id&.to_s,
      assignedExpertUsername: conversation.assigned_expert&.username,
      createdAt: conversation.created_at.iso8601,
      updatedAt: conversation.updated_at.iso8601,
      lastMessageAt: conversation.last_message_at&.iso8601,
      unreadCount: unread_count_for(conversation, viewer)
    }
  end

  def unread_count_for(conversation, viewer)
    conversation.messages.where.not(sender_id: viewer.id).where(is_read: false).count
  end
end

