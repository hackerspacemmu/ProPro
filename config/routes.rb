Rails.application.routes.draw do
  #Routes for static pages
  get 'privacy-policy', to: 'static_pages#privacy_policy', as: 'privacy_policy'
  get 'terms-of-service', to: 'static_pages#terms_of_service', as: 'terms_of_service'
  get 'about', to: 'static_pages#about'
  
  post "user/create"
  get "user/new_staff", to: "user#new_staff", as: :new_staff
  get "user/new_student", to: "user#new_student", as: :new_student
  get "user/profile"
  post "user/edit"
  post "user/:id/resend_invite", to: "user#resend_invite", as: :resend_invite

  root "homescreen#show"

  get "login", to: "sessions#new"
  resource :session

  resources :passwords, param: :token

  resources :comments, only: [:create] do
    member do
      patch 'soft_delete'
    end
  end

  resources :courses, only: [:index ,:show, :new, :create, :destroy] do
    member do
      get 'add_students'
      post 'handle_add_students'
      get 'add_lecturers'
      post 'handle_add_lecturers'
      get 'settings'
      post 'handle_settings'
      get 'export_csv'
      get 'profile/:participant_id/:participant_type', to: 'courses#profile', as: 'participant_profile'
    end

    resources :projects, only: [:show, :edit, :update, :create, :new] do
      member do
        patch :change_status
      end

      resources :progress_updates, only: [:show, :edit, :update, :create, :new, :destroy]
    end

    resources :topics, only: [:index, :show, :edit, :update, :create, :new, :destroy] do
      member do
        patch :change_status
      end

    end

    resources :participants, only: [:index]
  
    resources :lecturers, only: [:index, :show] do
      member do
        patch 'promote_to_coordinator'
        patch 'demote_to_lecturer'
      end

      resources :projects, only: [:show], controller: 'projects'
      
      resources :topics, only: [:index, :show, :edit, :update, :create, :new] do
        member do
          patch :change_status
        end
      end

    end

    resource :project_template, only: [:edit, :update, :show]
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
