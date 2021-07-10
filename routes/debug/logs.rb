# frozen_string_literal: true

class Nspack < Roda
  route 'logs', 'debug' do |r|
    #
    # LOG FILES - NGINX
    # --------------------------------------------------------------------------
    r.on 'nginx' do
      r.on 'access' do
        # 'access log - issue is sudo on some servers...'
        lines = params[:lines] || 100
        fn = '/var/log/nginx/access.log'
        view_log_file('Nginx access log', fn, lines)
      end
      r.on 'error' do
        # 'error log - issue is sudo on some servers...'
        lines = params[:lines] || 100
        fn = '/var/log/nginx/error.log.1'
        view_log_file('Nginx error log', fn, lines)
      end
    end

    #
    # LOG FILES - JOB QUE
    # --------------------------------------------------------------------------
    r.on 'job_que' do
      lines = params[:lines] || 100
      fn = 'log/que.log'
      view_log_file('Job queue log', fn, lines)
    end

    #
    # LOG FILES - API http calls
    # --------------------------------------------------------------------------
    r.on 'http' do
      lines = params[:lines] || 100
      fn = 'log/https.log'
      view_log_file('HTTP API Calls', fn, lines)
    end

    #
    # LOG FILES - ROBOT errs
    # --------------------------------------------------------------------------
    r.on 'robot' do
      lines = params[:lines] || 100
      fn = 'log/robot.log'
      view_log_file('Robot err log', fn, lines)
    end

    #
    # LOG FILES - DEV MODE - SQL LOGS
    # --------------------------------------------------------------------------
    r.on 'dev_sql' do
      lines = params[:lines] || 100
      fn = 'log/sql.log'
      view_log_file('Dev mode SQL log', fn, lines)
    end
  end
end
