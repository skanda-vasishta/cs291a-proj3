class ExpertProfilesController < ApplicationController
  include JwtAuthenticatable

  def show
    profile = find_or_build_profile
    render json: profile_payload(profile)
  end

  def update
    profile = find_or_build_profile
    if profile.update(profile_params)
      render json: profile_payload(profile)
    else
      render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_or_build_profile
    current_user.expert_profile || current_user.build_expert_profile.tap(&:save!)
  end

  def profile_params
    permitted = params.require(:expert_profile).permit(:bio, knowledge_base_links: [])
    permitted[:knowledge_base_links] ||= params[:knowledgeBaseLinks]
    permitted
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new(
      bio: params[:bio],
      knowledge_base_links: params[:knowledgeBaseLinks] || params[:knowledge_base_links]
    ).permit(:bio, knowledge_base_links: [])
  end

  def profile_payload(profile)
    {
      id: profile.id.to_s,
      userId: profile.user_id.to_s,
      bio: profile.bio,
      knowledgeBaseLinks: profile.knowledge_base_links || []
    }
  end
end

