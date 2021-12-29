# frozen_string_literal: true

require 'roda'
require 'net/http'

# Mock-up of a NoSoft Raspberry Pi robot
class App < Roda
  plugin :symbolized_params
  plugin :json_parser

  route do |r|
    r.root do
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">

            <title>Robot communicates via JSON</title>

          <style>
            html {
              font-family: sans-serif; /* 1 */
              -ms-text-size-adjust: 100%; /* 2 */
              -webkit-text-size-adjust: 100%; /* 2 */
              color: #000000c9;
            }
            #content {
              max-width: 1000px;
              margin: auto;
            }
            .robot_border {
              border: thin solid gray;
              background-color: lightgray;
              border-radius: 1em;
              padding: 1em;
            }

            .display {
              border: thin solid black;
              background-color: white;
              margin: 0.5em 1em 0 1em;
              padding: 0.4em 0;
            }

            .lcd {
              line-height: 1em;
              height: 1.5em;
              padding: 0 0.5em;
            }

            .leds {
              display: flex;
              justify-content: space-around;
            }

            .led_light {
              height: 2em;
              width: 2em;
              margin: 1em;
              border-radius: 50%;
            }
            #led_red {
              background-color: red;
            }
            #led_orange {
              background-color: orange;
            }
            #led_green {
              background-color: green;
            }
            div.button_line button {
              height: 2em;
              width: 2em;
              font-weight: bold;
              font-size: 4em;
            }
            div.button_line {
              display: flex;
              justify-content: space-between;
            }
            #btn1 {
              background-color: lightgreen;
            }
            #url_sent {
              color: #999;
              margin: 0.3em 0;
            }
          </style>
          </head>
          <body>
          <div id="content">
            <h1>Simulate JSON-response Robot button calls</h1>
            <div class="robot_border">
              <div class="display">
                <div id="lcd1" class="lcd"></div>
                <div id="lcd2" class="lcd"></div>
                <div id="lcd3" class="lcd"></div>
                <div id="lcd4" class="lcd"></div>
                <div id="lcd5" class="lcd"></div>
                <div id="lcd6" class="lcd"></div>
              </div>
              <div class="leds">
                <div id="led_red" class="led_light"></div>
                <div id="led_orange" class="led_light"></div>
                <div id="led_green" class="led_light"></div>
              </div>
              <div class="button_line">
                <button id="btn1" type="button" onclick="clearLcd();fetchJSONResponse();">1</button>
                <button id="btn3" type="button" disabled>2</button>
                <button id="btn2" type="button" disabled>3</button>
                <button id="btn4" type="button" disabled>4</button>
              </div>
            </div>
            <div>
              <div id="url_sent">&nbsp;</div>
              <select id="sel_urls"></select>
              <label><input type="checkbox" id="short_lines" name="short_lines" /> Simulate 22-character lines</label>
              <label><input type="checkbox" id="split_lines" name="split_lines" /> Simulate 34-character lines</label>
              <table>
              <tr>
                <th style="min-width:15em;text-align:right">Host</th><td><input type="text" id="url_host" value="localhost" /></td>
                <td style="padding:0.5em;" rowspan="6"><strong>JSON result</strong><br><textarea id="json_result" rows="12" cols="70" readonly></textarea></td>
              </tr>
              <tr>
                <th style="text-align:right">Port</th><td><input type="text" id="url_port" value="9296" /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p1"></label></th><td><input type="text" id="p1" hidden /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p2"></label></th><td><input type="text" id="p2" hidden /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p3"></label></th><td><input type="text" id="p3" hidden /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p4"></label></th><td><input type="text" id="p4" hidden /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p5"></label></th><td><input type="text" id="p5" hidden /></td>
              </tr>
              <tr>
                <th style="text-align:right">&nbsp;<label id="l_p6"></label></th><td><input type="text" id="p6" hidden /></td>
              </tr>
              </table>
            </div>
          </div>
          </body>
          <script>
            class HttpError extends Error {
              constructor(response) {
                super(`${response.status} for ${response.url}`);
                this.name = 'HttpError';
                this.response = response;
              }
            }

            const ledRed = document.getElementById('led_red');
            const ledOrange = document.getElementById('led_orange');
            const ledGreen = document.getElementById('led_green');
            const urlHost = document.getElementById('url_host');
            const urlPort = document.getElementById('url_port');
            const urlSent = document.getElementById('url_sent');
            const selUrls = document.getElementById('sel_urls');
            const shortLines = document.getElementById('short_lines');
            const splitLines = document.getElementById('split_lines');
            const lP1 = document.getElementById('l_p1');
            const p1 = document.getElementById('p1');
            const lP2 = document.getElementById('l_p2');
            const p2 = document.getElementById('p2');
            const lP3 = document.getElementById('l_p3');
            const p3 = document.getElementById('p3');
            const lP4 = document.getElementById('l_p4');
            const p4 = document.getElementById('p4');
            const lP5 = document.getElementById('l_p5');
            const p5 = document.getElementById('p5');
            const lP6 = document.getElementById('l_p6');
            const p6 = document.getElementById('p6');
            const jsonResult = document.getElementById('json_result');

            const clearLcd = function clearLcd() {
              document.querySelectorAll('.lcd').forEach((node) => {
                node.textContent='';
              });

              document.querySelectorAll('.led_light').forEach((node) => {
                node.style.backgroundColor='gray';
              });
              urlSent.innerHTML = '&nbsp;';
              jsonResult.value = '';
            };

            const setText = function setText(txt) {
              if (shortLines.checked) {
                return txt.substring(0, 22);
              } else if (splitLines.checked) {
                return txt.substring(0, 34);
              } else {
                return txt;
              }
            };

            const fetchJSONResponse = function fetchJSONResponse() {
              let payload = { host: urlHost.value, port: urlPort.value };
              const thisSet = urlSet.find((item) => {
                return item.payloadType === selUrls.value;
              });
              if (!thisSet) {
                urlSent.textContent = 'Not a valid payload...';
                lcd1.textContent = 'Select a payload below to test...';
                return;
              }
              payload[selUrls.value] = {};
              if (thisSet.p1) {
                payload[selUrls.value][thisSet.p1] = p1.value;
              }
              if (thisSet.p2) {
                payload[selUrls.value][thisSet.p2] = p2.value;
              }
              if (thisSet.p3) {
                payload[selUrls.value][thisSet.p3] = p3.value;
              }
              if (thisSet.p4) {
                payload[selUrls.value][thisSet.p4] = p4.value;
              }
              if (thisSet.p5) {
                payload[selUrls.value][thisSet.p5] = p5.value;
              }
              if (thisSet.p6) {
                payload[selUrls.value][thisSet.p6] = p6.value;
              }
              let tmpLoad = Object.assign({}, payload);
              delete tmpLoad['host'];
              delete tmpLoad['port'];
              urlSent.textContent = JSON.stringify(tmpLoad);
              fetch('/make_json_call', {
                method: 'POST',
                credentials: 'same-origin',
                headers: {
                  'Accept': 'application/json, text/plain, */*',
                  'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload),
              })
              .then(response => response.json())
              .then((data) => {
                jsonResult.value = JSON.stringify(data).replaceAll(',', ',\\n').replaceAll('{', '{\\n').replaceAll('}', '\\n}');
                if(data['error']) {
                  ledRed.style.backgroundColor='red';
                  lcd1.textContent = 'There was an error from the robot simulator. See JSON result below';
                  return;
                }
                if (data.responseStation) {
                  lcd6.textContent = '= STATION mode =';
                }
                if (data.responseUser) {
                  lcd6.textContent = '= USER mode =';
                }
                if (data.responseKeypad) {
                  lcd6.textContent = '= KEYPAD mode =';
                }
                let inner = data.responseStation;
                if (!inner) {
                  console.log('no inner');
                  inner = data.responseUser;
                }
                if (!inner) {
                  inner = data.responseKeypad;
                }
                if (!inner) {
                  inner = {};
                }
                if (inner['red'] && inner['red'] === 'true') {
                  ledRed.style.backgroundColor='red';
                }
                if (inner['orange'] && inner['orange'] === 'true') {
                  ledOrange.style.backgroundColor='orange';
                }
                if (inner['green'] && inner['green'] === 'true') {
                  ledGreen.style.backgroundColor='green';
                }
                if (inner['LCD1']) {
                  lcd1.textContent = setText(inner['LCD1']);
                }
                if (inner['LCD2']) {
                  lcd2.textContent = setText(inner['LCD2']);
                }
                if (inner['LCD3']) {
                  lcd3.textContent = setText(inner['LCD3']);
                }
                if (inner['LCD4']) {
                  lcd4.textContent = setText(inner['LCD4']);
                }
                if (inner['LCD5']) {
                  lcd5.textContent = setText(inner['LCD5']);
                }
                if (inner['LCD6']) {
                  lcd6.textContent = setText(inner['LCD6']);
                }
                // TODO: handle confirm etc type responses...
                console.log('Got response:', data);
              }).catch((data) => {
                console.log('CATCH');
                console.debug(data);
              });
            };

            const urlSet = [
              {
                payloadType: 'requestPing',
                p1: 'MAC',
                p2: null,
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
              {
                payloadType: 'requestDateTime',
                p1: 'MAC',
                p2: null,
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
              {
                payloadType: 'requestSetup',
                p1: 'MAC',
                p2: 'type',
                p3: 'status',
                p4: null,
                p5: null,
                p6: null,
                dp3: 'REQUEST',
              },
              {
                payloadType: 'publishScaleWeight',
                p1: 'MAC',
                p2: 'id',
                p3: 'barcode',
                p4: 'weight',
                p5: 'units',
                p6: 'status',
                dp5: 'kg',
                dp6: 'NORMAL',
              },
              {
                payloadType: 'publishBarcodeScan',
                p1: 'MAC',
                p2: 'id',
                p3: 'barcode',
                p4: 'session',
                p5: 'status',
                p6: null,
                dp5: 'NORMAL',
              },
              {
                payloadType: 'publishButton',
                p1: 'MAC',
                p2: 'id',
                p3: 'barcode', // This might be: value
                p4: 'button',  // This might be: session
                p5: null,
                p6: null,
              },
              {
                payloadType: 'publishStatus',
                p1: 'MAC',
                p2: 'status',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
              {
                payloadType: 'publishLogon',
                p1: 'MAC',
                p2: 'id',
                p3: 'session',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                payloadType: 'publishLogoff',
                p1: 'MAC',
                p2: 'session',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
            ];

            document.addEventListener('DOMContentLoaded', () => {
              const option = document.createElement('option');
              option.value = '';
              option.text = 'Select an API call to test';
              selUrls.appendChild(option);
              urlSet.forEach((node) => {
                const option = document.createElement('option');
                option.value = node.payloadType;
                option.text = node.payloadType;
                selUrls.appendChild(option);
              });
              selUrls.addEventListener('change', (event) => {
                const payloadType = event.target.value;
                let thisSet = urlSet.find((item) => {
                  return item.payloadType === payloadType;
                });
                if (thisSet === undefined) {
                  thisSet = {};
                }
                if (thisSet.p1) {
                  lP1.textContent = thisSet.p1;
                  p1.hidden = false;
                  if (thisSet.dp1) {
                    p1.value = thisSet.dp1;
                  }
                } else {
                  lP1.textContent = '';
                  p1.value = '';
                  p1.hidden = true;
                }
                if (thisSet.p2) {
                  lP2.textContent = thisSet.p2;
                  p2.hidden = false;
                  if (thisSet.dp2) {
                    p2.value = thisSet.dp2;
                  }
                } else {
                  lP2.textContent = '';
                  p2.value = '';
                  p2.hidden = true;
                }
                if (thisSet.p3) {
                  lP3.textContent = thisSet.p3;
                  p3.hidden = false;
                  if (thisSet.dp3) {
                    p3.value = thisSet.dp3;
                  }
                } else {
                  lP3.textContent = '';
                  p3.value = '';
                  p3.hidden = true;
                }
                if (thisSet.p4) {
                  lP4.textContent = thisSet.p4;
                  p4.hidden = false;
                  if (thisSet.dp4) {
                    p4.value = thisSet.dp4;
                  }
                } else {
                  lP4.textContent = '';
                  p4.value = '';
                  p4.hidden = true;
                }
                if (thisSet.p5) {
                  lP5.textContent = thisSet.p5;
                  p5.hidden = false;
                  if (thisSet.dp5) {
                    p5.value = thisSet.dp5;
                  }
                } else {
                  lP5.textContent = '';
                  p5.value = '';
                  p5.hidden = true;
                }
                if (thisSet.p6) {
                  lP6.textContent = thisSet.p6;
                  p6.hidden = false;
                  if (thisSet.dp6) {
                    p6.value = thisSet.dp6;
                  }
                } else {
                  lP6.textContent = '';
                  p6.value = '';
                  p6.hidden = true;
                }
              }, false);
            });
          </script>
        </html>
      HTML
    end

    r.on 'make_json_call' do
      response['Content-Type'] = 'application/json'

      host = params.delete(:host)
      port = params.delete(:port)
      uri = URI.parse("http://#{host}:#{port}/messcada/robot/api")
      http = Net::HTTP.new(uri.host, uri.port)

      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
      request.body = params.to_json

      response = http.request(request)
      if response.code == '200'
        response.body
      else
        str = response.body.split("<div class='crossbeams-error-note'><p><strong>Error:</strong></p>").last.split('</div>').first
        { error: 'The server crashed - please check server logs.', message: str || 'Unknown' }.to_json
      end

    rescue Timeout::Error
      { error: 'The call to the server timed out.' }.to_json
    rescue Errno::ECONNREFUSED
      { error: 'The connection was refused. Perhaps the server is not running.' }.to_json
    rescue StandardError => e
      { error: "There was an error: #{e.message}" }.to_json
    end

    r.on 'make_call' do
      response['Content-Type'] = 'application/xml'

      uri = URI.parse(params[:url])
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)
      response.body

    rescue Timeout::Error
      "<local_err>\n  <msg>The call to the server timed out.</msg>\n</local_err>"
    rescue Errno::ECONNREFUSED
      "<local_err>\n  <msg>The connection was refused. Perhaps the server is not running.</msg>\n</local_err>"
    rescue StandardError => e
      "<local_err>\n  <msg>There was an error: #{e.message}</msg>\n</local_err>"
    end
  end
end

run App.freeze.app
