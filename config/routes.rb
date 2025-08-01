Rails.application.routes.draw do
  post "user/create"
  get "user/new_staff"
  get "user/new_student"
  get "user/profile"
  post "user/edit"

  root "homescreen#show"

  resources :sessions
  resources :passwords, param: :token

  resources :courses, only: [:show, :new, :create] do
    member do
      get 'add_people'
      post 'handle_add_people'
      get 'settings'
      post 'handle_settings'
    end

    resources :projects, only: [:index, :show, :edit, :update] do
      member do
        patch :change_status
      end

      resources :comments, only:[:create]
    end

    resources :topics, only: [:index, :show, :edit, :update] do
      member do
        patch :change_status
      end
    end
  
    resources :lecturers, only: [:index, :show] do
      resources :topics, only: [:index, :show, :edit, :update] do
        member do
          patch :change_status
        end
      end
    end

    resource  :project_template, only: [:new, :create, :edit, :update, :show] do
      get 'new_field', on: :member
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
