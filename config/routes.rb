RVT::Engine.routes.draw do
  root to: 'console_sessions#index'

  resources :console_sessions do
    member do
      put :input
      get :pending_output
      put :configuration
    end
  end
end
