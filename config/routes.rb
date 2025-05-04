Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get '/youtube/authorize', to: 'youtube#authorize'
  get '/youtube/oauth2callback', to: 'youtube#oauth2callback'
  post '/youtube/upload', to: 'youtube#upload'
  post 'youtube_shorts', to: 'youtube_shorts#create'
end
