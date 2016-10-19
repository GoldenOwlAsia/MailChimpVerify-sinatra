require 'sinatra'
require './env' if File.exist?('env.rb')
require 'braintree'
require 'json'

Braintree::Configuration.environment = :sandbox
Braintree::Configuration.merchant_id = ENV['BRAINTREE_MERCHANT_ID']
Braintree::Configuration.public_key = ENV['BRAINTREE_PUBLIC_KEY']
Braintree::Configuration.private_key = ENV['BRAINTREE_PRIVATE_KEY']

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
    { success: false, error: "Something went wrong while processing your transaction. Please try again!" }.to_json
  end  
end

def generate_client_token
  Braintree::ClientToken.generate
end