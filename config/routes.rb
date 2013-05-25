Ruralcloud::Application.routes.draw do
  # auto routing for standard challenge operations
  resources :challenges

  # extra route for adding user to challenge
  match "/challenges/enter/:id" => "challenges#enter", :as => :enter_challenge

  # custom routes for devise user stuff
  devise_for :users,
             :path => "",
             :path_names => { :sign_up  => "register",
                              :sign_in  => "login",
                              :sign_out => "logout"
                            }

  get "home/index"
  root :to => 'home#index'

  post "home/index"
  root :to => 'home#index'

  post "home/send_message"
  root :to => 'home#index'

  post "challenges/send_compile"
  root :to => "challenges#send_compile"
end
