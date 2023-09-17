Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  namespace :api do
    namespace :v1 do
      namespace :servers do
        resources :status, only: [:show]
      end
      namespace :texture do
        resources :face, only: [:show]
      end
    end
  end
end
