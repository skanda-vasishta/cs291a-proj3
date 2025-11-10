module Api
  class ConversationsController < ApplicationController
    include JwtAuthenticatable
    include ConversationPresenter

    def updates
      return unauthorized_user unless current_user.id.to_s == params[:userId]

      scope = Conversation.where("initiator_id = :id OR assigned_expert_id = :id", id: current_user.id)
      scope = scope.where("updated_at > ?", parsed_since) if parsed_since
      scope = scope.order(updated_at: :desc).includes(:initiator, :assigned_expert, :messages)

      render json: scope.map { |conversation| conversation_payload(conversation, viewer: current_user) }
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

