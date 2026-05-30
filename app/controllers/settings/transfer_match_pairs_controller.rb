class Settings::TransferMatchPairsController < ApplicationController
  layout "settings"

  def index
    @pairs = Current.family.transfer_match_pairs.includes(:account_a, :account_b)
    @accounts = Current.family.accounts.visible.alphabetically
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
end
