require 'sinatra'

require 'trackbook/pass'

module Trackbook
  class App < Sinatra::Base
    set :root, File.expand_path("..", __FILE__)

    if ENV['RACK_ENV'] == 'production'
      require 'rack/ssl'
      use Rack::SSL
    end

    configure do
      require 'redis'
      if url = ENV['REDISTOGO_URL']
        uri = URI.parse(url)
        $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      else
        $redis = Redis.new
      end
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
      pass_type_id, serial_number = Pass.generate_pass($redis, PASS_TYPE_ID)
      redirect "/v1/passes/#{pass_type_id}/#{serial_number}"
    end

    post "/v1/devices/:device_id/registrations/:pass_type_id/:serial_number" do
      request.body.rewind
      data = JSON.parse(request.body.read)

      unless pass = Pass.find_authenticated_pass($redis, params[:pass_type_id], params[:serial_number], apple_auth_token)
        halt 401
      end

      if Pass.register_pass($redis, params[:pass_type_id], params[:serial_number], params[:device_id], data['pushToken'])
        status 201
      else
        status 200
      end
    end

    delete "/v1/devices/:device_id/registrations/:pass_type_id/:serial_number" do
      unless pass = Pass.find_authenticated_pass($redis, params[:pass_type_id], params[:serial_number], apple_auth_token)
        halt 401
      end

      Pass.unregister_pass($redis, params[:pass_type_id], params[:serial_number], params[:device_id])
      status 200
    end

    get "/v1/passes/:pass_type_id/:serial_number" do
      unless pass = Pass.find_pass($redis, params[:pass_type_id], params[:serial_number])
        halt 401
      end

      content_type 'application/vnd.apple.pkpass'
      attachment "#{params[:serial_number]}.pkpass"
      Pass.build_pass_pkpass(pass, "#{request.base_url}/")
    end

    post "/v1/log" do
      warn "LOG: #{params.inspect}"
      ""
    end

    def apple_auth_token
      if env && env['HTTP_AUTHORIZATION']
        env['HTTP_AUTHORIZATION'].split(" ").last
      end
    end
  end
end
