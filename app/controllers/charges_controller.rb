class ChargesController < ApplicationController
  def create
    customer = Stripe::Customer.create(
      email: current_user.email,
      card: params[:stripeToken]
    )
 
    charge = Stripe::Charge.create(
      customer: customer.id, 
      amount: 15_00, 
      description: "BigMoney Membership - #{current_user.email}",
      currency: 'usd'
    )

    if charge.paid == true
      current_user.premium!
      current_user.charges.create(
        stripe_charge_id: charge.id,
        amount: charge.amount    
      )
      current_user.update(stripe_id: customer.id)
      flash[:notice] = "Thanks for all the money, #{current_user.email}! Feel free to pay me again."
      redirect_to user_path(current_user) 
    end

    rescue Stripe::CardError => e
      flash[:alert] = e.message
      redirect_to user_path(current_user)
  end

  def destroy
    charge = Charge.find(params[:id])
    stripe_charge = Stripe::Charge.retrieve(charge.stripe_charge_id)

    if refund = stripe_charge.refunds.create(amount: 15_00)
      current_user.standard!
      charge.update(refunded: true)
      current_user.wikis.where(private: true).each do |wiki|
        wiki.update(private: false)
    end
      flash[:notice] = "You are now a lowly standard user"
    else
      flash[:alert] = 'Downgrade failed'
    end

    redirect_to user_path(current_user)
  end
end
