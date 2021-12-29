# frozen_string_literal: true

require 'roda'
require 'net/http'

# Mock-up of a NoSoft Raspberry Pi robot
class App < Roda
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

            <title>MesScada Mock</title>

            <link rel="stylesheet" href="default.min.css">
            <script src="highlight.min.js"></script>
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

            #sent_url {
              border: thin solid black;
              background-color: white;
              margin: 0.5em 1em 0 1em;
              padding: 0.4em 0;
            }
            #sent_xml {
              border: thin solid black;
              background-color: white;
              margin: 0.5em 1em 0 1em;
              padding: 0.4em 0;
              height: 20vh;
            }
            #received_xml {
              border: thin solid black;
              background-color: white;
              margin: 0.5em 1em 0 1em;
              padding: 0.4em 0;
              height: 20vh;
              overflow-y: scroll;
            }
            #sent_url::before {
              content: "URL: ";
              color: green;
            }
            #sent_xml::before {
              content: "XML sent";
              color: green;
            }
            #received_xml::before {
              content: "XML received";
              color: green;
            }
            #xml_rec_text {
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
            #url_to_call {
             display: inline-block;
              color: #999;
              margin: 0.3em 0;
            }
          </style>
          </head>
          <body>
          <div id="content">
            <h1>Simulate NoSoft MesScada XML calls</h1>
            <div class="robot_border">
              <div class="sent">
                <div id="sent_url"></div>
                <div id="sent_xml"><pre><code id="xml_sent_text" class="language-xml"></code></pre>
                </div>
                <div id="received_xml"><pre><code id="xml_rec_text" class="language-xml"></code></pre>
                </div>
              </div>
              <div class="leds">
                <div id="led_red" class="led_light"></div>
                <div id="led_green" class="led_light"></div>
              </div>
              <div class="button_line">
                <button id="btn1" type="button" onclick="clearLcd();fetchResponse();">Simulate Call</button>
              </div>
            </div>
            <div>
              <select id="sel_urls"></select>
              <div id="url_to_call">&nbsp;</div>
              <table>
              <tr>
                <th style="min-width:15em;text-align:right">Host</th><td><input type="text" id="url_host" value="localhost" /></td>
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
            const urlToCall = document.getElementById('url_to_call');
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
            const urlSent = document.getElementById('sent_url');
            const xmlSent = document.getElementById('xml_sent_text');
            const xmlResult = document.getElementById('xml_rec_text');

            const clearLcd = function clearLcd() {
              document.querySelectorAll('.led_light').forEach((node) => {
                node.style.backgroundColor='gray';
              });
              urlToCall.innerHTML = '&nbsp;';
              xmlSent.innerHTML = '&nbsp;';
              xmlResult.innerHTML = '&nbsp;';
            };

            const setText = function setText(txt) {
              return txt;
            };

            const xmlCanTip = function xmlCanTip() {
              return `<ContainerMove PID="200"  Module="${p1.value}" Name="172.16.35.199_41" TransactionType="" Op="" Su="" Mode="5" BinNumber="${p2.value}"  LotNumber="" />`
            }

            const xmlTip = function xmlTip() {
              return `<ContainerMove PID="200"  Module="${p1.value}" Name="172.16.35.199_41" TransactionType="" Op="" Su="" Mode="6" BinNumber="${p2.value}"  LotNumber="1288218" />`
            }

            const xmlLabelLine = function xmlLabelLine() {
              return `<ProductLabel PID="223" Module="${p1.value}" Name="172.16.35.109" Op="" Su="" Mode="6" Input1="${p2.value}" Input2="${p3.value}" " LabelRenderAmount="1" Store="true" Printer="PRN-01" Mass="0.0" />`
            }

            const xmlLabelDp = function xmlLabelDp() {
              return `<ProductLabel PID="223" Module="${p1.value}" Name="172.16.35.109" Op="" Su="" Mode="6" BinNumber="${p2.value}" Input1="${p3.value}" Input2="${p4.value}" " LabelRenderAmount="1" Store="true" Printer="PRN-01" Mass="0.0" />`
            }

            const xmlModuleOnly = function xmlModuleOnly() {
              return `<XMLData device="${p1.value}" />`;
            };

            const fetchResponse = function fetchResponse() {
              let form = new FormData();
              const urlBase = selUrls.value;
              const thisSet = urlSet.find((item) => {
                return item.name === urlBase;
              });
              if (!thisSet) {
                urlSent.textContent = 'Not a valid URL...' + urlBase;
                return;
              }

              let url = `http://${urlHost.value}:${urlPort.value}${thisSet.url}`;
              form.append('url', url);
              urlSent.textContent = url;
              const xml = thisSet.func.call();
              form.append('body', xml);
              xmlSent.textContent = xml;

              urlSent.textContent = url;

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
                xmlResult.textContent = data;
                const parser = new DOMParser();
                const xmlDoc = parser.parseFromString(data, "text/xml");

                let txt = xmlDoc.getElementsByTagName('local_err')[0];
                if (txt) {
                  ledRed.style.backgroundColor='red';
                  // lcd1.textContent = 'There was an error from the robot simulator. See XML result below';
                  return;
                }

                 txt = xmlDoc.getElementsByTagName('status')[0];
                 if (txt && txt.childNodes.length > 0 && txt.childNodes[0].nodeValue === 'true') {
                     ledGreen.style.backgroundColor='green';
                 } else {
                   txt = xmlDoc.getElementsByTagName('Status')[0];
                   if (txt && txt.childNodes.length > 0 && txt.childNodes[0].nodeValue === 'true') {
                     ledGreen.style.backgroundColor='green';
                   } else {
                     ledRed.style.backgroundColor='red';
                   }
                 }

                 hljs.highlightAll();

              }).catch((data) => {
                console.log('CATCH');
                console.debug(data);
              });
            };

            const urlSet = [
              {
                name: 'Can tip bin?',
                url: '/messcada/xml/bin_tipping/can_dump',
                p1: 'module',
                p2: 'bin_number',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
                func: xmlCanTip,
              },
              {
                name: 'Tip bin',
                url: '/messcada/xml/bin_tipping/dump',
                p1: 'module',
                p2: 'bin_number',
                p3: null,
                p4: null,
                p5: null,
                p6: null,
                func: xmlTip,
              },
              {
                name: 'Label - line scanning',
                url: '/messcada/xml/carton_labeling',
                p1: 'module',
                p2: 'packpoint',
                p3: 'identifier',
                p4: null,
                p5: null,
                p6: null,
                func: xmlLabelLine,
              },
              {
                name: 'Label - Dedicated Pack',
                url: '/messcada/xml/carton_labeling',
                p1: 'module',
                p2: 'bin_number',
                p3: 'packpoint',
                p4: 'identifier',
                p5: null,
                p6: null,
                func: xmlLabelDp,
              },
              {
                name: 'Change device to group incentive',
                url: '/messcada/xml/system_resource/change_to_group_login',
                p1: 'module',
                p2: null,
                p3: null,
                p4: null,
                p5: null,
                p6: null,
                func: xmlModuleOnly,
              },
              {
                name: 'Change device to individual incentive',
                url: '/messcada/xml/system_resource/change_to_individual_login',
                p1: 'module',
                p2: null,
                p3: null,
                p4: null,
                p5: null,
                p6: null,
                func: xmlModuleOnly,
              },
            ];

            document.addEventListener('DOMContentLoaded', () => {
              const option = document.createElement('option');
              option.value = '';
              option.text = 'Select a call to test';
              selUrls.appendChild(option);
              urlSet.forEach((node) => {
                const option = document.createElement('option');
                option.value = node.name;
                option.text = node.name;
                selUrls.appendChild(option);
              });
              selUrls.addEventListener('change', (event) => {
                const url = event.target.value;
                let thisSet = urlSet.find((item) => {
                  return item.name === url;
                });
                if (thisSet === undefined) {
                  thisSet = {};
                }
                urlToCall.innerHTML = thisSet.url;
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

    r.on 'default.min.css' do
      response['Content-Type'] = 'text/css'

      File.read('default.min.css')
    end

    r.on 'highlight.min.js' do
      response['Content-Type'] = 'application/javascript'

      File.read('highlight.min.js')
    end

    r.on 'make_call' do
      response['Content-Type'] = 'application/xml'

      uri = URI.parse(params.delete(:url))
      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 5
      http.read_timeout = 10
      request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/xml')
      request.body = params[:body]

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
