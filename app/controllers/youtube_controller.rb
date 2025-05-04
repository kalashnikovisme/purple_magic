require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

class YoutubeController < ApplicationController
  def authorize
    user_id = 'default'
    authorizer = google_authorizer
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      redirect_to authorizer.get_authorization_url(base_url: oauth2callback_url)
    else
      redirect_to youtube_upload_path
    end
  end

  def oauth2callback
    authorizer = google_authorizer
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: 'default',
      code: params[:code],
      base_url: oauth2callback_url
    )
    redirect_to youtube_upload_path
  end

  def upload
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.authorization = google_authorizer.get_credentials('default')

    video = Google::Apis::YoutubeV3::Video.new(
      snippet: {
        title: 'My Short Video #Shorts',
        description: 'Uploaded via API #Shorts',
        tags: ['shorts'],
        category_id: '22' # "People & Blogs"
      },
      status: {
        privacy_status: 'public'
      }
    )

    video_path = Rails.root.join('path', 'to', 'your_video.mp4') # <= update this

    File.open(video_path, 'rb') do |file|
      youtube.insert_video('snippet,status', video, upload_source: file, content_type: 'video/*')
    end

    render plain: 'YouTube Short uploaded successfully!'
  end

  private

  def google_authorizer
    client_id = Google::Auth::ClientId.from_file(Rails.root.join('config', 'client_secret.json'))
    token_store = Google::Auth::Stores::FileTokenStore.new(file: Rails.root.join('config', 'tokens.yaml'))
    Google::Auth::UserAuthorizer.new(client_id, Google::Apis::YoutubeV3::AUTH_YOUTUBE_UPLOAD, token_store)
  end
end
