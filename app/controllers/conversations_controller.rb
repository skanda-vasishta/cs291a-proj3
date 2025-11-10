class ConversationsController < ApplicationController
  include JwtAuthenticatable
  include ConversationPresenter

  def index
    conversations = base_scope
                     .includes(:initiator, :assigned_expert, :messages)
                     .order(updated_at: :desc)

    render json: conversations.map { |conversation| conversation_payload(conversation, viewer: current_user) }
  end

  def show
    conversation = find_conversation
    return unless conversation

    render json: conversation_payload(conversation, viewer: current_user)
  end

  def create
    conversation = current_user.initiated_conversations.build(conversation_params)

    if conversation.save
      render json: conversation_payload(conversation, viewer: current_user), status: :created
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
    if params[:conversation].present?
      params.require(:conversation).permit(:title)
    else
      { title: params[:title] }
    end
  end

end

