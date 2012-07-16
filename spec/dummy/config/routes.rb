Dummy::Application.routes.draw do
  root to: "welcome#index"

  match "passthrough", to: "welcome#index"
  match "users/:username", to: "welcome#index"
end
