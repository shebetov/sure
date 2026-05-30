class Settings::TransferMatchGroupsController < ApplicationController
  layout "settings"

  def index
    @groups = Current.family.transfer_match_groups.includes(transfer_match_group_memberships: :account)
    @accounts = Current.family.accounts.visible.alphabetically
    @family = Current.family
  end

  def create
    @group = Current.family.transfer_match_groups.build(name: params[:name].presence)

    if @group.save
      redirect_to settings_transfer_match_groups_path
    else
      @groups = Current.family.transfer_match_groups.includes(transfer_match_group_memberships: :account)
      @accounts = Current.family.accounts.visible.alphabetically
      @family = Current.family
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Current.family.transfer_match_groups.find(params[:id]).destroy
    redirect_to settings_transfer_match_groups_path
  end

  def settings
    if Current.family.update(settings_params)
      redirect_to settings_transfer_match_groups_path
    else
      @groups = Current.family.transfer_match_groups.includes(transfer_match_group_memberships: :account)
      @accounts = Current.family.accounts.visible.alphabetically
      @family = Current.family
      render :index, status: :unprocessable_entity
    end
  end

  private

    def settings_params
      params.require(:family).permit(:transfer_match_date_window, :transfer_match_exchange_rate_tolerance).tap do |p|
        p[:transfer_match_date_window] = p[:transfer_match_date_window].to_i.clamp(0, 30) if p[:transfer_match_date_window].present?
        p[:transfer_match_exchange_rate_tolerance] = p[:transfer_match_exchange_rate_tolerance].to_d.clamp(0.0, 1.0) if p[:transfer_match_exchange_rate_tolerance].present?
      end
    end
end
