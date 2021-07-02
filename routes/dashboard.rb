# frozen_string_literal: true

class Nspack < Roda
  route('dashboard') do |r|
    interactor = MasterfilesApp::DashboardInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    r.on 'nodash', String do |key|
      "<h1>There are no dashboards configured for \"#{key}\".</h1>"
    end

    r.on 'image', String do |key|
      view(inline: "<img src=\"/dashboard_images/#{key}\">",
           layout: 'layout_dash_image')
    end

    r.on 'text', String do |key|
      content = interactor.text_for(key) || "<h1>NO CONTENT FOR #{key}</H1>"
      view(inline: content,
           layout: 'layout_dash_text')
    end

    r.on 'preview_page', String do |key_plus_index|
      key, index = key_plus_index.split('_')
      url = interactor.url_for(key, index.to_i)
      content = <<~HTML
        <script>
          function ChangeSrc() {
            document.getElementById('frame').src = '#{url}';
          }

          window.onload = ChangeSrc;
        </script>
      HTML
      view(inline: content, layout: 'layout_dash_control')
    end

    r.on String do |key|
      # Note ALL dash keys must be lowercase...
      @dashboard_name, url_set = interactor.dashboard_for(key.downcase)
      r.redirect "/dashboard/nodash/#{key}" if @dashboard_name.nil?
      content = <<~HTML
        <script>
          const frameSRC = Array(
            #{url_set.map { |a| "'#{a[0]}', #{a[1]}" }.join(', ')}
            );
          let i = 0;
          const len = frameSRC.length;
          let move = len > 2;

          function ChangeSrc() {
            if (i >= len) { i = 0; } // start over
            document.getElementById('frame').src = frameSRC[i++];
            if (move) {
              setTimeout('ChangeSrc()', (frameSRC[i++]*1000));
            }
          }

          window.onload = ChangeSrc;
        </script>
      HTML
      view(inline: content, layout: 'layout_dash_control')
    end
  end
end
