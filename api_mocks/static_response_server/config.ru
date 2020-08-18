# frozen_string_literal: true

require 'roda'
require 'net/http'
require 'rouge'
require 'nokogiri'

# rubocop:disable Metrics/BlockLength

# Mock-up of a NoSoft Server so MesScada or Robots can call and
# receive particular responses.
class App < Roda # rubocop:disable Metrics/ClassLength
  plugin :symbolized_params

  URL_SET = [
    '/messcada/rmt/bin_tipping',
    '/messcada/rmt/bin_tipping/weighing',
    '/messcada/production/carton_labeling',
    '/messcada/production/carton_verification',
    '/messcada/production/carton_verification/weighing/labeling',
    '/messcada/fg/pallet_weighing',
    '/messcada/hr/register_id',
    '/messcada/hr/logon',
    '/messcada/hr/logoff',
    '/messcada/hr/logon_with_no?',
    '/messcada/hr/logoff_with_no?',
    '/messcada/carton_palletizing/scan_carton',
    '/messcada/carton_palletizing/qc_out',
    '/messcada/carton_palletizing/return_to_bay',
    '/messcada/carton_palletizing/refresh',
    '/messcada/carton_palletizing/complete',
    '/messcada/yesnoresponse/yes',
    '/messcada/yesnoresponse/no'
  ].freeze

  route do |r|
    r.root do
      opts = URL_SET.map { |u| %(<option value="#{u.delete_prefix('/').tr('/', '_')}">#{u}</option>) }.join("\n")
      <<~HTML
        <h1 style="color:#333">A Mock NSPack server</h1>
        <form action="/edit">
        <p>
          Choose a URL to change its XML response:
        </p>
        <p>
          Note the two <em>yesnoresponses</em> are not to be called directly. These are chosen as possible URLS to call after showing Yes/No choice to the user.
        </p>
        <select name="url">
          #{opts}
        </select>
        <p>
          <input type="submit" value="Change response" />
        </p>
        </form>
      HTML
    end

    r.on 'edit' do
      key = params[:url]
      xml = if File.exist?(File.join('responses', "#{key}.xml"))
              File.read(File.join('responses', "#{key}.xml"))
            else
              default_response(key.tr('_', '/').delete_suffix('.xml').insert(0, '/'), key)
            end

      res = unpack_xml(xml)
      state = if res.green == 'true'
                'green'
              elsif res.orange == 'true'
                'orange'
              else
                'red'
              end
      yesval = if res.yes_url.nil? || res.yes_url.empty?
                 ''
               elsif res.yes_url == 'noop'
                 'noop'
               else
                 'yesurl'
               end
      noval = if res.no_url.nil? || res.no_url.empty?
                ''
              elsif res.no_url == 'noop'
                'noop'
              else
                'nourl'
              end
      <<~HTML
        <h1 style="color:#333">A Mock NSPack server</h1>
        <a href="/">HOME</a>
        <h2 style="color:#333">#{key.tr('_', '/').insert(0, '/')}</h2>
        <form action="/update">
        <table>
          <tbody>
            <tr><th style="text-align:right">State</th><td><select name="state">
              <option value="green" #{state == 'green' ? 'selected' : ''}>Green</option>
              <option value="orange" #{state == 'orange' ? 'selected' : ''}>Orange</option>
              <option value="red" #{state == 'red' ? 'selected' : ''}>Red</option>
              </select></td></tr>
            <tr><th style="text-align:right">Message</th><td><input type="text" name="msg" style="width:30em" value="#{(res.msg || '').tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd1</th><td><input type="text" name="lcd1" style="width:30em" value="#{res.lcd1.tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd2</th><td><input type="text" name="lcd2" style="width:30em" value="#{res.lcd2.tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd3</th><td><input type="text" name="lcd3" style="width:30em" value="#{res.lcd3.tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd4</th><td><input type="text" name="lcd4" style="width:30em" value="#{res.lcd4.tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd5</th><td><input type="text" name="lcd5" style="width:30em" value="#{res.lcd5.tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">lcd6</th><td><input type="text" name="lcd6" style="width:30em" value="#{res.lcd6.tr('"', '`')}" /><br>
              <em><smaller>NOTE: If left blank, the mock server will echo the parameters in lcd6.</smaller></em>
            </td></tr>
            <tr><th style="text-align:right">confirm_msg</th><td><input type="text" name="confirm" style="width:30em" value="#{(res.text || '').tr('"', '`')}" /></td></tr>
            <tr><th style="text-align:right">yes_url</th><td><select name="yesurl" >
            <option value="">Not selected</option>
            <option value="yesurl" #{yesval == 'yesurl' ? 'selected' : ''}>/messcada/yesnoresponse/yes</option>
            <option value="noop" #{yesval == 'noop' ? 'selected' : ''}>No Op</option>
            </select></td></tr>
            <tr><th style="text-align:right">no_url</th><td><select name="nourl" >
            <option value="">Not selected</option>
            <option value="nourl" #{noval == 'nourl' ? 'selected' : ''}>/messcada/yesnoresponse/no</option>
            <option value="noop" #{noval == 'noop' ? 'selected' : ''}>No Op</option>
            </select></td></tr>
          </tbody>
        </table>
        <input type="hidden" name="url_key" value="#{key}" />
        <input type="submit" value="Save new response" />
        </form>
        <pre style="font-size:large">
        #{format_xml(xml)}
        </pre>
      HTML
    end

    r.on 'update' do
      yesval = if params[:yesurl].nil? || params[:yesurl].empty? || params[:yesurl] == 'noop'
                 'noop'
               else
                 "#{request.base_url}/messcada/yesnoresponse/yes"
               end
      noval = if params[:nourl].nil? || params[:nourl].empty? || params[:nourl] == 'noop'
                'noop'
              else
                "#{request.base_url}/messcada/yesnoresponse/no"
              end
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.robot_feedback do
          xml.status params[:state] == 'green' ? 'true' : 'false'
          xml.green params[:state] == 'green' ? 'true' : 'false'
          xml.orange params[:state] == 'orange' ? 'true' : 'false'
          xml.red params[:state] == 'red' ? 'true' : 'false'
          xml.msg params[:msg]
          xml.lcd1 params[:lcd1]
          xml.lcd2 params[:lcd2]
          xml.lcd3 params[:lcd3]
          xml.lcd4 params[:lcd4]
          xml.lcd5 params[:lcd5]
          xml.lcd6 params[:lcd6]
          unless params[:confirm].empty?
            xml.confirm do
              xml.text_ params[:confirm]
              xml.yes_url yesval
              xml.no_url noval
            end
          end
        end
      end

      File.open(File.join('responses', "#{params[:url_key]}.xml"), 'w') { |f| f.puts(builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS | Nokogiri::XML::Node::SaveOptions::FORMAT)) }

      <<~HTML
        <h1 style="color:#333">A Mock NSPack server</h1>
        <a href="/">HOME</a>
        <h2 style="color:#333">#{params[:url_key].tr('_', '/').insert(0, '/')}</h2>
        <p style="color:green;font-weight:bold">
           Changes have been saved...
        </p>
        <pre style="font-size:large">
        #{format_xml(builder.to_xml(save_with: Nokogiri::XML::Node::SaveOptions::NO_EMPTY_TAGS | Nokogiri::XML::Node::SaveOptions::FORMAT))}
        </pre>
      HTML
    end

    r.on 'messcada' do
      response['Content-Type'] = 'application/xml'
      r.on 'rmt' do
        r.on 'bin_tipping' do
          r.on 'weighing' do
            respond(request.path, params)
          end
          r.on 'multi_bin_weighing' do
            respond(request.path, params)
          end
          respond(request.path, params)
        end
      end
      r.on 'production' do
        r.on 'carton_labeling' do
          respond(request.path, params)
        end
        r.on 'carton_verification' do
          r.on 'weighing/labeling' do
            respond(request.path, params)
          end
          respond(request.path, params)
        end
      end
      r.on 'fg/pallet_weighing' do
        respond(request.path, params)
      end
      r.on 'hr' do
        r.on 'register_id' do
          respond(request.path, params)
        end
        r.on 'logon' do
          respond(request.path, params)
        end
        r.on 'logoff' do
          respond(request.path, params)
        end
      end
      r.on 'yesnoresponse' do
        r.on 'yes' do
          respond(request.path, params)
        end
        r.on 'no' do
          respond(request.path, params)
        end
      end
      r.on 'carton_palletizing' do
        r.on 'scan_carton' do
          respond(request.path, params)
        end
        r.on 'qc_out' do
          respond(request.path, params)
        end
        r.on 'return_to_bay' do
          respond(request.path, params)
        end
        r.on 'refresh' do
          respond(request.path, params)
        end
        r.on 'complete' do
          respond(request.path, params)
        end
      end
    rescue StandardError => e
      respond_with_error(e.message)
    end
  end

  def default_response(url, key, params = nil)
    <<~XML
      <robot_feedback>
        <status>true</status>
        <red>false</red>
        <green>true</green>
        <orange>false</orange>
        <msg></msg>
        <lcd1>Default response</lcd1>
        <lcd2>URL: #{url}</lcd2>
        <lcd3></lcd3>
        <lcd4>There is no saved XML response file named "#{key}" yet</lcd4>
        <lcd5></lcd5>
        <lcd6>#{params ? params.map { |k, v| "#{k}=#{v}" }.join(', ') : ''}</lcd6>
      </robot_feedback>
    XML
  end

  def respond_with_error(message)
    <<~XML
      <robot_feedback>
        <status>false</status>
        <red>true</red>
        <green>false</green>
        <orange>false</orange>
        <msg></msg>
        <lcd1>AN ERROR OCCURRED</lcd1>
        <lcd2>(In the MOCK server itself)</lcd2>
        <lcd3>ERR: #{message}</lcd3>
        <lcd4>MOCK SERVER ERROR</lcd4>
        <lcd5>MOCK SERVER ERROR</lcd5>
        <lcd6>MOCK SERVER ERROR</lcd6>
      </robot_feedback>
    XML
  end

  def respond(url, params = nil)
    key = "#{url.delete_prefix('/').tr('/', '_')}.xml"
    if File.exist?(File.join('responses', key))
      xml = File.read(File.join('responses', key))
      xml.gsub!('<lcd6></lcd6>', "<lcd6>#{params ? params.map { |k, v| "#{k}=#{v}" }.join(', ') : ''}</lcd6>") if params && xml.include?('<lcd6></lcd6>')
      xml
    else
      default_response(url, key, params)
    end
  end

  def format_xml(xml)
    theme = Rouge::Themes::Github
    formatter = Rouge::Formatters::HTMLInline.new(theme)
    lexer = Rouge::Lexers::XML.new
    formatter.format(lexer.lex(xml))
  end

  def unpack_xml(xml) # rubocop:disable Metrics/AbcSize
    parse_opt = Nokogiri::XML::ParseOptions.new.noblanks
    doc = Nokogiri::XML(xml, nil, nil, parse_opt)
    hs = doc.children.first.element_children.map(&:name).zip(doc.children.first.element_children.map(&:text))
    unless doc.children.first.children.last.children.empty?
      confs = doc.children.first.children.last.children
      ends = confs.map(&:name).zip(confs.map(&:text))
      ends.each do |k, v|
        hs << [k, v]
      end
    end
    OpenStruct.new(hs.to_h)
  end
end

run App.freeze.app

# rubocop:enable Metrics/BlockLength
