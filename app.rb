require 'sinatra'
require 'dotenv'
require 'braintree'
require 'json'
require 'stripe'
require 'byebug'
Dotenv.load
Braintree::Configuration.environment = ENV['BRAINTREE_ENV']
Braintree::Configuration.merchant_id = ENV['BRAINTREE_MERCHANT_ID']
Braintree::Configuration.public_key = ENV['BRAINTREE_PUBLIC_KEY']
Braintree::Configuration.private_key = ENV['BRAINTREE_PRIVATE_KEY']
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

get '/api/v1/transactions/client_token' do
  @client_token = generate_client_token
  content_type :json
  { success: true, data: @client_token }.to_json
end

post '/api/v1/transactions' do
  result = Braintree::Transaction.sale(amount: params[:amount],
                                          payment_method_nonce: params[:payment_method_nonce],
                                          customer: {
                                            first_name: params[:cus_first_name],
                                            last_name: params[:cus_last_name]
                                          })
  if result.success?
    status 201
    { success: true }.to_json
  else
    status 422
    { success: false, error: 'Something went wrong while processing your transaction. Please try again!' }.to_json
  end
end

post '/api/v1/stripe/card_token' do
  @result = Stripe::Token.create(
    card: {
      number: params[:number],
      exp_month: params[:exp_month],
      exp_year: params[:exp_year],
      cvc: params[:cvc]
    }
  )
  if @result
    status 201
    { success: true, data: @result }.to_json
  else
    status 422
    { success: false }.to_json
  end
end

post '/api/v1/stripe/charge' do
  @customer = Stripe::Customer.create(
    email: params[:email],
    source: params[:token_stripe],
    description: params[:description_create]
  )

  @charge = Stripe::Charge.create(
    amount: params[:amount],
    description: params[:description_charge],
    customer: @customer.id
  )

  if @charge
    status 201
    { success: true }.to_json
  else
    status 422
    { success: false }.to_json
  end
end

def generate_client_token
  Braintree::ClientToken.generate
end
