Dummy::Application.routes.draw do
  root to: "welcome#index"

  match "skipme", to: "welcome#index"
  match "users/:username", to: "welcome#index"
end
