Ruralcloud::Application.routes.draw do
  resources :challenges


  devise_for :users,
             :path => "",
             :path_names => { :sign_up  => "register",
                              :sign_in  => "login",
                              :sign_out => "logout",
                              :edit     => "preferences"
                            }

  get "home/index"

  root :to => 'home#index'
end
