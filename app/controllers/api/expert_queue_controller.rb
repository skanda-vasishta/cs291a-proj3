module Api
  class ExpertQueueController < ApplicationController
    include JwtAuthenticatable
    include ConversationPresenter

    def updates
      return unauthorized_user unless current_user.id.to_s == params[:expertId]

      waiting = Conversation.waiting.where(assigned_expert_id: nil).where.not(initiator_id: current_user.id)
      assigned = Conversation.where(assigned_expert_id: current_user.id)

      if parsed_since
        waiting = waiting.where("updated_at > ?", parsed_since)
        assigned = assigned.where("updated_at > ?", parsed_since)
      end

      render json: [{
        waitingConversations: waiting.map { |conversation| conversation_payload(conversation, viewer: current_user) },
        assignedConversations: assigned.map { |conversation| conversation_payload(conversation, viewer: current_user) }
      }]
    end

    private

    def parsed_since
      @parsed_since ||= begin
        Time.iso8601(params[:since]) if params[:since].present?
      rescue ArgumentError
        nil
      end
    end

    def unauthorized_user
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end

