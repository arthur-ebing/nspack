# frozen_string_literal: true

require 'roda'
require 'net/http'

# rubocop:disable Metrics/BlockLength
# Mock-up of a NoSoft Raspberry Pi robot
class App < Roda # rubocop:disable Metrics/ClassLength
  plugin :symbolized_params

  route do |r|
    r.root do
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="utf-8">
            <meta http-equiv="X-UA-Compatible" content="IE=edge">
            <meta name="viewport" content="width=device-width, initial-scale=1">

            <title>Robot Pi</title>

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
              width: 6em;
              margin: 1em;
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
              height: 4em;
              width: 20em;
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
            <h1>Simulate NoSoft MesServer Robot button calls</h1>
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
                <button id="btn1" type="button" onclick="clearLcd();fetchResponse();">Button 1</button>
                <button id="btn3" type="button" disabled>Button 3</button>
              </div>
              <div class="button_line">
                <button id="btn2" type="button" disabled>Button 2</button>
                <button id="btn4" type="button" disabled>Button 4</button>
              </div>
              <div class="button_line">
                <button id="btn5" type="button" onclick="clearLcd(); document.getElementById('lcd1').textContent='I am some kind of NoSoft module';">Systeminfo</button>
                <button id="btn6" type="button" onclick="clearLcd(); document.getElementById('lcd1').textContent='I might be on a network (#{request.ip})';">Networkinfo</button>
              </div>
            </div>
            <div>
              <div id="url_sent">&nbsp;</div>
              <select id="sel_urls"></select>
              <table>
              <tr>
                <th style="min-width:15em;text-align:right">Host</th><td><input type="text" id="url_host" value="localhost" /></td>
                <td style="padding:0.5em;" rowspan="6"><strong>XML result</strong><br><textarea id="xml_result" rows="12" cols="70" readonly></textarea></td>
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
            const xmlResult = document.getElementById('xml_result');

            const clearLcd = function clearLcd() {
              document.querySelectorAll('.lcd').forEach((node) => {
                node.textContent='';
              });

              document.querySelectorAll('.led_light').forEach((node) => {
                node.style.backgroundColor='gray';
              });
              urlSent.innerHTML = '&nbsp;';
              xmlResult.value = '';
            };

            const fetchResponse = function fetchResponse() {
              const urlBase = selUrls.value;
              const thisSet = urlSet.find((item) => {
                return item.url === urlBase;
              });
              if (!thisSet) {
                urlSent.textContent = 'Not a valid URL...';
                lcd1.textContent = 'Select a URL below to test...';
                return;
              }

              let url = `http://${urlHost.value}:${urlPort.value}${urlBase}`;
              if (thisSet.p1) {
                url += `${thisSet.p1}=${p1.value}`
              }
              if (thisSet.p2) {
                url += `&${thisSet.p2}=${p2.value}`
              }
              if (thisSet.p3) {
                url += `&${thisSet.p3}=${p3.value}`
              }
              if (thisSet.p4) {
                url += `&${thisSet.p4}=${p4.value}`
              }
              if (thisSet.p5) {
                url += `&${thisSet.p5}=${p5.value}`
              }
              if (thisSet.p6) {
                url += `&${thisSet.p6}=${p6.value}`
              }

              urlSent.textContent = url;

              let form = new FormData();
              form.append('url', url);

              fetch('/make_call', {
                method: 'POST',
                credentials: 'same-origin',
                headers: new Headers({
                  'X-Custom-Request-Type': 'Fetch',
                }),
                body: form,
              })
              .then((response) => {
                if (response.status === 200) {
                  return response.text();
                }
                throw new HttpError(response);
              })
              .then((data) => {
                xmlResult.value = data;
                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(data, "text/xml");

                let txt = xmlDoc.getElementsByTagName('local_err')[0];
                if (txt) {
                  ledRed.style.backgroundColor='red';
                  lcd1.textContent = 'There was an error from the robot simulator. See XML result below';
                  return;
                }

                txt = xmlDoc.getElementsByTagName('red')[0];
                if (txt && txt.childNodes.length > 0) {
                  if (txt.childNodes[0].nodeValue === 'true') {
                    ledRed.style.backgroundColor='red';
                  }
                  txt = xmlDoc.getElementsByTagName('orange')[0].childNodes[0].nodeValue;
                  if (txt === 'true') {
                    ledOrange.style.backgroundColor='orange';
                  }
                  txt = xmlDoc.getElementsByTagName('green')[0].childNodes[0].nodeValue;
                  if (txt === 'true') {
                    ledGreen.style.backgroundColor='green';
                  }
                } else {
                  txt = xmlDoc.getElementsByTagName('status')[0];
                  if (txt.childNodes.length > 0 && txt.childNodes[0].nodeValue === 'true') {
                      ledGreen.style.backgroundColor='green';
                  } else {
                    ledRed.style.backgroundColor='red';
                  }
                }

                txt = xmlDoc.getElementsByTagName('msg')[0];
                if (txt && txt.childNodes.length > 0) {
                  lcd1.textContent = txt.childNodes[0].nodeValue;
                } else {
                  txt = xmlDoc.getElementsByTagName('lcd1')[0];
                  console.log(txt);
                  if (txt.childNodes.length > 0) {
                    lcd1.textContent = txt.childNodes[0].nodeValue;
                  }
                  txt = xmlDoc.getElementsByTagName('lcd2')[0];
                  if (txt.childNodes.length > 0) {
                    lcd2.textContent = txt.childNodes[0].nodeValue;
                  }
                  txt = xmlDoc.getElementsByTagName('lcd3')[0];
                  if (txt.childNodes.length > 0) {
                    lcd3.textContent = txt.childNodes[0].nodeValue;
                  }
                  txt = xmlDoc.getElementsByTagName('lcd4')[0];
                  if (txt.childNodes.length > 0) {
                    lcd4.textContent = txt.childNodes[0].nodeValue;
                  }
                  txt = xmlDoc.getElementsByTagName('lcd5')[0];
                  if (txt.childNodes.length > 0) {
                    lcd5.textContent = txt.childNodes[0].nodeValue;
                  }
                  txt = xmlDoc.getElementsByTagName('lcd6')[0];
                  if (txt.childNodes.length > 0) {
                    lcd6.textContent = txt.childNodes[0].nodeValue;
                  }
                }
              }).catch((data) => {
                console.log('CATCH');
                console.debug(data);
              });
            };

            const urlSet = [
              {
                url: '/messcada/rmt/bin_tipping?',
                p1: 'device',
                p2: 'bin_number',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/rmt/bin_tipping/weighing?',
                p1: 'device',
                p2: 'bin_number',
                p3: 'gross_weight',
                p4: 'measurement_unit',
                p5: null,
                p6: null,
                dp4: 'kg',
              },
              {
                url: '/messcada/production/carton_labeling?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/production/carton_verification?',
                p1: 'device',
                p2: 'carton_number',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/production/carton_verification/weighing/labeling?',
                p1: 'device',
                p2: 'carton_number',
                p3: 'gross_weight',
                p4: 'measurement_unit',
                p5: 'card_reader',
                p6: 'identifier',
                dp4: 'kg',
              },
              {
                url: '/messcada/fg/pallet_weighing?',
                p1: 'device',
                p2: 'bin_number',
                p3: 'gross_weight',
                p4: 'measurement_unit',
                p5: null,
                p6: null,
                dp4: 'kg',
              },
              {
                url: '/messcada/hr/register_id?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'value',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/hr/logon?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/hr/logoff?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/palletize/scan_carton?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: 'carton_number',
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/palletize/qc_out?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/palletize/return_to_bay?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/palletize/refresh?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
              {
                url: '/messcada/palletize/complete?',
                p1: 'device',
                p2: 'card_reader',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
              },
            ];

            document.addEventListener('DOMContentLoaded', () => {
              const option = document.createElement('option');
              option.value = '';
              option.text = 'Select a URL to test';
              selUrls.appendChild(option);
              urlSet.forEach((node) => {
                const option = document.createElement('option');
                option.value = node.url;
                option.text = node.url;
                selUrls.appendChild(option);
              });
              selUrls.addEventListener('change', (event) => {
                const url = event.target.value;
                let thisSet = urlSet.find((item) => {
                  return item.url === url;
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
# rubocop:enable Metrics/BlockLength

run App.freeze.app
