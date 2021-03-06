Interapptive::Application.routes.draw do

  root :to => 'admin::users#index', :constraints => lambda { |request| request.cookies['auth_token'] && request.cookies['is_admin'] }
  root :to => 'storybooks#index', :constraints => lambda { |request| request.cookies['auth_token'] }
  root :to => 'user_sessions#new'

  #get  'users/sign_up'  => 'users#new',             :as => 'sign_up'
  get  'users/sign_in'  => 'user_sessions#new',     :as => 'sign_in'
  post 'users/sign_in'  => 'user_sessions#create',  :as => ''
  match 'users/sign_out' => 'user_sessions#destroy', :as => 'sign_out'
  get  'users/settings'  => 'users#edit'

  resource :user do
    collection { get :show_signed_in_as_user }
  end

  get  'password_reset'      => 'password_resets#new',   :as => :new_password_reset
  get  'password_resets/:id' => 'password_resets#edit',  :as => :edit_password_reset
  put  'password_resets/:id' => 'password_resets#update'
  post 'password_resets'     => 'password_resets#create'

  resource :compiler
  resource :confirmation, only: [:new, :create]
  resource :term,         only: [:new, :create], :path_names => { :new => 'accept' }, :path => 'terms'
  resource :kmetrics,   only: :create

  resources :images
  resources :videos
  resources :sounds
  resources :fonts

  get '/storybooks/main', to: redirect('/assets/init_storybook.js')
  get '/storybooks/res/:name', to: redirect('/assets/res/%{name}.png')
  resources :storybooks do
    resources :scenes do
      collection { put :sort }
    end

    resources :fonts
    resources :images
    resources :videos
    resources :sounds
    resources :assets, only: [:create, :index]

    resource :application_information, only: [:create, :update]
    resource :subscription_publish_information, only: [:update]
    resource :subscription_publish_request, only: [:create]

    get 'simulator/show' => 'simulator#show'
    get 'simulator/main', to: redirect('/assets/simulator.js')
  end

  resources :scenes do
    #resources :actions

    resources :keyframes do
      collection { put :sort }
    end
  end

  resources :keyframes

  resource :zencoder, :controller => :zencoder, :only => :create

  namespace :admin do
    root :to => 'users#index'

    resources :subscription_users do
      collection do
        get 'search'
      end

      member do
        post 'restore'
      end
    end

    resources :users do
      collection do
        get 'search'
      end
      member do
        post 'send_invitation'
        post 'restore'
      end
    end

    resource :subscription_publisher, only: :create

    resources :publish_requests,              only: [:index, :show, :update]
    resources :subscription_publish_requests, only: [:index, :show, :update]
    resources :storybook_assignments,         only: [:edit, :update]
    resources :storybook_archives,            only: [:create]
    resources :auto_alignments,               only: [:create]
  end
end
