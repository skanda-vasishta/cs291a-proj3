module Api
  class MessagesController < ApplicationController
    include JwtAuthenticatable
    include MessagePresenter

    def updates
      return unauthorized_user unless current_user.id.to_s == params[:userId]

      messages = Message
                 .joins(:conversation)
                 .where("conversations.initiator_id = :id OR conversations.assigned_expert_id = :id", id: current_user.id)
      messages = messages.where("messages.created_at > ?", parsed_since) if parsed_since
      messages = messages.includes(:sender).order(created_at: :desc)

      render json: messages.map { |message| message_payload(message) }
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

