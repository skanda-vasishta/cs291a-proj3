class MessagesController < ApplicationController
  include JwtAuthenticatable

  before_action :set_conversation
  before_action :ensure_participant!

  def index
    messages = @conversation.messages.includes(:sender).order(:created_at)
    render json: messages.map { |message| message_payload(message) }
  end

  def create
    message = @conversation.messages.build(content: message_content)
    message.sender = current_user
    message.sender_role = sender_role_for(current_user)

    if message.save
      @conversation.update!(last_message_at: message.created_at)
      render json: message_payload(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find_by(id: conversation_id_param)
    return if @conversation

    render json: { error: "Conversation not found" }, status: :not_found
  end

  def ensure_participant!
    return if [@conversation.initiator_id, @conversation.assigned_expert_id].compact.include?(current_user.id)

    render json: { error: "Forbidden" }, status: :forbidden
  end

  def sender_role_for(user)
    if user.id == @conversation.initiator_id
      :initiator
    elsif @conversation.assigned_expert_id.present? && user.id == @conversation.assigned_expert_id
      :expert
    else
      raise ActiveRecord::RecordInvalid, "User not part of conversation"
    end
  end

  def conversation_id_param
    params[:conversation_id] ||
      params.dig(:message, :conversation_id) ||
      params[:conversationId]
  end

  def message_content
    params.dig(:message, :content) || params[:content]
  end

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

