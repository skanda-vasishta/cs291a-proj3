class ExpertController < ApplicationController
  include JwtAuthenticatable
  include ConversationPresenter

  before_action :load_conversation, only: %i[claim unclaim]

  def queue
    waiting = Conversation.waiting.where(assigned_expert_id: nil).where.not(initiator_id: current_user.id)
    assigned = Conversation.where(assigned_expert_id: current_user.id)

    render json: {
      waitingConversations: waiting.map { |conversation| conversation_payload(conversation, viewer: current_user) },
      assignedConversations: assigned.map { |conversation| conversation_payload(conversation, viewer: current_user) }
    }
  end

  def claim
    if @conversation.assigned_expert_id.present?
      return render json: { error: "Conversation is already assigned to an expert" }, status: :unprocessable_entity
    end

    ExpertAssignment.transaction do
      @conversation.update!(assigned_expert: current_user, status: :active)
      ExpertAssignment.create!(conversation: @conversation, expert: current_user)
    end

    render json: { success: true }
  end

  def unclaim
    unless @conversation.assigned_expert_id == current_user.id
      return render json: { error: "You are not assigned to this conversation" }, status: :forbidden
    end

    ExpertAssignment.transaction do
      assignment = @conversation.expert_assignments.where(expert: current_user, status: ExpertAssignment::STATUSES[:active]).order(created_at: :desc).first
      assignment&.update!(status: ExpertAssignment::STATUSES[:resolved], resolved_at: Time.current)
      @conversation.update!(assigned_expert_id: nil, status: :waiting)
    end

    render json: { success: true }
  end

  def history
    assignments = current_user.expert_assignments.order(assigned_at: :desc)

    render json: assignments.map { |assignment| assignment_payload(assignment) }
  end

  private

  def load_conversation
    @conversation = Conversation.find_by(id: params[:conversation_id])
    return if @conversation

    render json: { error: "Conversation not found" }, status: :not_found
  end

  def assignment_payload(assignment)
    {
      id: assignment.id.to_s,
      conversationId: assignment.conversation_id.to_s,
      expertId: assignment.expert_id.to_s,
      status: assignment.status,
      assignedAt: assignment.assigned_at&.iso8601,
      resolvedAt: assignment.resolved_at&.iso8601,
      rating: nil
    }
  end
end

