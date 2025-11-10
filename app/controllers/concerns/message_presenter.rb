module MessagePresenter
  extend ActiveSupport::Concern

  private

  def message_payload(message)
    {
      id: message.id.to_s,
      conversationId: message.conversation_id.to_s,
      senderId: message.sender_id.to_s,
      senderUsername: message.sender.username,
      senderRole: message.sender_role,
      content: message.content,
      timestamp: message.created_at.iso8601,
      isRead: ActiveModel::Type::Boolean.new.cast(message.is_read)
    }
  end
end

