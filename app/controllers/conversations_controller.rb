class ConversationsController < ApplicationController
  include JwtAuthenticatable

  def index
    conversations = base_scope
                     .includes(:initiator, :assigned_expert, :messages)
                     .order(updated_at: :desc)

    render json: conversations.map { |conversation| conversation_payload(conversation) }
  end

  def show
    conversation = find_conversation
    return unless conversation

    render json: conversation_payload(conversation)
  end

  def create
    conversation = current_user.initiated_conversations.build(conversation_params)

    if conversation.save
      render json: conversation_payload(conversation), status: :created
    else
      render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def base_scope
    Conversation.where("initiator_id = :id OR assigned_expert_id = :id", id: current_user.id)
  end

  def find_conversation
    conversation = base_scope.includes(:initiator, :assigned_expert, :messages).find_by(id: params[:id])
    return conversation if conversation

    render json: { error: "Conversation not found" }, status: :not_found
    nil
  end

  def conversation_params
    params.require(:conversation).permit(:title)
  end

  def conversation_payload(conversation)
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
      unreadCount: unread_count(conversation)
    }
  end

  def unread_count(conversation)
    conversation.messages
                .where.not(sender_id: current_user.id)
                .where(is_read: false)
                .count
  end
end

