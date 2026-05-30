class Settings::TransferMatchGroupMembershipsController < ApplicationController
  before_action :set_group

  def create
    @membership = @group.transfer_match_group_memberships.build(account_id: params[:account_id])

    if @membership.save
      redirect_to settings_transfer_match_groups_path
    else
      redirect_to settings_transfer_match_groups_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    @group.transfer_match_group_memberships.find(params[:id]).destroy
    redirect_to settings_transfer_match_groups_path
  end

  private

    def set_group
      @group = Current.family.transfer_match_groups.find(params[:transfer_match_group_id])
    end
end
