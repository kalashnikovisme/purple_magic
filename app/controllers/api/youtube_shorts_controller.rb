require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'tempfile'

module Api
  class YoutubeShortsController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authorize_request!

    def create
      return render json: { error: 'Missing video file' }, status: :bad_request unless params[:file]

      file = params[:file]
      title = params[:title].presence || "Untitled Short #Shorts"
      tempfile = Tempfile.new(['short', '.mp4'], binmode: true)
      tempfile.write(file.read)
      tempfile.rewind

      youtube = Google::Apis::YoutubeV3::YouTubeService.new
      youtube.authorization = google_authorizer.get_credentials('default')

      video = Google::Apis::YoutubeV3::Video.new(
        snippet: {
          title: title.include?('#Shorts') ? title : "#{title} #Shorts",
          description: 'Uploaded via API #Shorts',
          category_id: '22',
          tags: ['shorts']
        },
        status: {
          privacy_status: 'public'
        }
      )

      youtube.insert_video('snippet,status', video, upload_source: tempfile, content_type: 'video/*')

      render json: { message: 'Short uploaded successfully!' }, status: :created
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message }, status: :internal_server_error
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    private

    def authorize_request!
      auth_header = request.headers['Authorization']
      expected_token = Rails.application.credentials.dig(:youtube, :api_token)

      unless auth_header&.match(/^Bearer\s+(.*)$/) && Regexp.last_match(1) == expected_token
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    def google_authorizer
      client_id = Google::Auth::ClientId.from_file(Rails.root.join('config', 'client_secret.json'))
      token_store = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join('config', 'tokens.yaml'))
      Google::Auth::UserAuthorizer.new(client_id, Google::Apis::YoutubeV3::AUTH_YOUTUBE_UPLOAD, token_store)
    end
  end
end
