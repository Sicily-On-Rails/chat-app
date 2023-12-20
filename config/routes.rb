Rails.application.routes.draw do
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  get 'rooms/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"


  get '/signin', to: 'sessions#new'
  post '/signin', to: 'sessions#create'
  delete 'signout', to: 'sessions#destroy'

  resources :rooms do 
    resources :messages
  end
  resources :users

  root 'rooms#index'
end


