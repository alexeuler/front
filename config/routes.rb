Front::Application.routes.draw do
  resources :post_likes, :only => [:update, :destroy]
  #get "omniauth_callbacks/vkontakte"
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  resources :users, :only => [:index, :destroy]
  resources :posts
  root 'users#index'
end
