Rails.application.routes.draw do
  post "user/create"
  get "user/new_staff", to: "user#new_staff", as: :new_staff
  get "user/new_student", to: "user#new_student", as: :new_student
  get "user/profile"
  post "user/edit"

  root "homescreen#show"

  resource :session
  resources :passwords, param: :token

  resources :courses, only: [:show, :new, :create, :destroy] do
    member do
      get 'add_students'
      post 'handle_add_students'
      get 'add_lecturers'
      post 'handle_add_lecturers'
      get 'settings'
      post 'handle_settings'
    end

    resources :projects, only: [:show, :edit, :update, :create, :new] do
      member do
        patch :change_status
      end

      resources :comments do
        member do
          patch 'soft_delete'
        end
      end
    end

    resources :topics, only: [:index, :show, :edit, :update, :create, :new] do
      member do
        patch :change_status
      end

      resources :comments do
        member do
          patch 'soft_delete'
        end
      end
      
    end
  
    resources :lecturers, only: [:index, :show] do
      resources :topics, only: [:index, :show, :edit, :update, :create, :new] do
        member do
          patch :change_status
        end

        resources :comments do
          member do
            patch 'soft_delete'
          end
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
