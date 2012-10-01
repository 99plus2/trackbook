require 'sinatra'

require 'trackbook/pass'
require 'trackbook/pass_presenter'
require 'trackbook/track'

module Trackbook
  class App < Sinatra::Base
    set :root, File.expand_path("..", __FILE__)

    if ENV['RACK_ENV'] == 'production'
      require 'rack/ssl'
      use Rack::SSL
    end

    get "/" do
      erb :index
    end

    if ENV['PASS_TYPE_ID']
      PASS_TYPE_ID = ENV['PASS_TYPE_ID']
    else
      raise "Missing Passbook Type ID. Please set PASS_TYPE_ID."
    end

    post "/" do
      pass_type_id, serial_number = Pass.generate_pass(PASS_TYPE_ID, params[:tracking_number], params[:description])
      redirect "/v1/passes/#{pass_type_id}/#{serial_number}"
    end

    post "/v1/devices/:device_id/registrations/:pass_type_id/:serial_number" do
      request.body.rewind
      data = JSON.parse(request.body.read)

      unless pass = Pass.find_authenticated_pass(params[:pass_type_id], params[:serial_number], apple_auth_token)
        halt 401
      end

      if Pass.register_pass(params[:pass_type_id], params[:serial_number], params[:device_id], data['pushToken'])
        status 201
      else
        status 200
      end
    end

    get "/v1/devices/:device_id/registrations/:pass_type_id" do
      serial_numbers = Pass.find_device_registered_serial_numbers(params[:pass_type_id], params[:device_id])

      if serial_numbers.any?
        {
          'lastUpdated' => Time.now,
          'serialNumbers' => serial_numbers
        }.to_json
      else
        status 204
      end
    end

    delete "/v1/devices/:device_id/registrations/:pass_type_id/:serial_number" do
      unless pass = Pass.find_authenticated_pass(params[:pass_type_id], params[:serial_number], apple_auth_token)
        halt 401
      end

      Pass.unregister_pass(params[:pass_type_id], params[:serial_number], params[:device_id])
      status 200
    end

    get "/v1/passes/:pass_type_id/:serial_number" do
      unless pass = Pass.find_pass(params[:pass_type_id], params[:serial_number])
        halt 401
      end

      pass.merge!({'activity' => Track.track_shipment(pass['serial_number'])})

      content_type 'application/vnd.apple.pkpass'
      attachment "#{params[:serial_number]}.pkpass"
      PassPresenter.present_pkpass(pass, "#{request.base_url}/")
    end

    post "/v1/log" do
      request.body.rewind
      data = JSON.parse(request.body.read)
      data['logs'].each { |l| warn l }
      ""
    end

    def apple_auth_token
      if env && env['HTTP_AUTHORIZATION']
        env['HTTP_AUTHORIZATION'].split(" ").last
      end
    end
  end
end
