Ruralcloud::Application.routes.draw do
  # auto routing for standard challenge operations
  resources :challenges

  # extra route for adding user to challenge
  match "/challenges/enter/:id" => "challenges#enter", :as => :enter_challenge

  match "/challenges/submit/:id" => "challenges#submit", :as => :submit_challenge

  match "/leaderboards/:id" => "challenges#leaderboard", :as => :show_leaderboard

  match "/leaderboards" => "challenges#global_leaderboard", :as => :global_leaderboard

  match "/challenges/show_outcomes/:id/user=:user_id" => "challenges#show_outcomes", :as => :show_outcomes

  match "/users/:id" => "users#show", :as => :user

  match "/challenges/kick/:challenge/:user" => "challenges#kick", :as => :kick

  # custom routes for devise user stuff
  devise_for :users,
             :path => "",
             :path_names => { :sign_up  => "register",
                              :sign_in  => "login",
                              :sign_out => "logout"
                            },
             :controllers => { :omniauth_callbacks => "users/omniauth_callbacks",
                               :registrations => "registrations" }

  get "home/index"
  root :to => 'home#index'

  post "home/index"
  root :to => 'home#index'

  post "challenges/send_compile"
  root :to => "challenges#send_compile"

  post "challenges/send_eval"
  root :to => "challenges#send_eval"

  post "challenges/run_tests"
  root :to => "challenges#run_tests"

  post "challenges/push_github"
  root :to => "challenges#push_github"

  post "challenges/report_error"
  root :to => "challenges#report_error"

  post "pusher/auth"
end
