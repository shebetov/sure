class Settings::TransferMatchPairsController < ApplicationController
  layout "settings"

  def index
    @pairs = Current.family.transfer_match_pairs.includes(:account_a, :account_b)
    @accounts = Current.family.accounts.visible.alphabetically
    @family = Current.family
  end

  def create
    @pair = Current.family.transfer_match_pairs.build(
      account_a_id: params[:account_a_id],
      account_b_id: params[:account_b_id]
    )

    if @pair.save
      redirect_to settings_transfer_match_pairs_path
    else
      @pairs = Current.family.transfer_match_pairs.includes(:account_a, :account_b)
      @accounts = Current.family.accounts.visible.alphabetically
      flash.now[:alert] = @pair.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    Current.family.transfer_match_pairs.find(params[:id]).destroy
    redirect_to settings_transfer_match_pairs_path
  end

  def settings
    if Current.family.update(settings_params)
      redirect_to settings_transfer_match_pairs_path
    else
      @pairs = Current.family.transfer_match_pairs.includes(:account_a, :account_b)
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
