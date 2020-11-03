# frozen_string_literal: true

class Nspack < Roda
  route 'robot', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # ROBOT API
    # --------------------------------------------------------------------------
    r.on 'api' do
      response['Content-Type'] = 'application/json'
      # p params
      # {:requestPing=>{:MAC=>"00:11:22:33:44:55"}}
      action_type = params.keys.first
      if action_type == :requestPing
        { responsePong: params[:requestPing] }.to_json
      elsif action_type == :requestDateTime
        { responseDateTime: { status: 'OK', MAC: params[:requestDateTime][:MAC], date: Time.now.strftime('%Y-%m-%d'), time: Time.now.strftime('%H:%M:%S') } }.to_json
      else
        {}.to_json
      end
    end
  end
end
