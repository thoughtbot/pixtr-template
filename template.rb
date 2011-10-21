files_to_remove = %w(
  README
  Gemfile
  public/index.html
  app/assets/images/rails.png
  config/database.yml
)
run "rm #{files_to_remove.join(' ')}"

file "README", "Pixtr"

file "Gemfile", <<-EOF
source :rubygems

gem 'rails', '~> 3.1.1'
gem 'pg'

gem 'clearance'
gem 'jquery-rails'
gem 'flutie'
gem 'formtastic'
gem 'haml'
gem 'high_voltage'
gem 'hoptoad_notifier'
gem 'paperclip'

group :development, :test do
  gem 'rspec-rails'
end

group :assets do
  gem "uglifier"
end

group :test do
  gem 'cucumber-rails'
  gem 'cucumber-rails-training-wheels'
  gem 'factory_girl_rails'
  gem 'bourne'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'timecop'
  gem 'launchy'
  gem 'shoulda'
end
EOF

file "config/database.yml", <<-EOF
development:
  adapter: postgresql
  encoding: unicode
  database: pixtr_development
  pool: 5
  min_messages: warning

test:
  adapter: postgresql
  encoding: unicode
  database: pixtr_test
  pool: 5
  min_messages: warning

production:
  adapter: postgresql
  encoding: unicode
  database: pixtr_production
  pool: 5
EOF

run "bundle"

file ".rspec", "--colour"
inside "spec" do
  file "spec_helper.rb", <<-EOF
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda'
require 'paperclip/matchers'

Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
  config.use_transactional_fixtures = true
  config.include Paperclip::Shoulda::Matchers
end
EOF
end

generate("cucumber:install", "--rspec --capybara")
generate("cucumber_rails_training_wheels:install")

rake "db:create"
rake "db:migrate"

generate("clearance:install")
generate("clearance:features")

rake "db:migrate"
rake "db:test:prepare"

rake "flutie:install"

inside "app/views/pages" do
  file "home.html.erb", "<h1>Pixtr</h1>"
end
route "root :to => 'high_voltage/pages#show', :id => 'home'"

inside "features/support" do
  file "capybara.rb", "Capybara.save_and_open_page_path = 'tmp'"
end

def insert(at, file, text)
  lines = File.readlines(file)
  lines.insert at, "#{text}\n"
  File.open(file, "w") { |f| f.write lines.join }
end

insert -6, "app/views/layouts/application.html.erb", <<-EOF
  <% flash.each do |key, value| -%>
    <div class="flash <%= key %>"><%= value %></div>
  <% end -%>

  <% if signed_in? %>
    <%= link_to "Sign out", sign_out_path, :method => :delete %>
  <% else %>
    <%= link_to "Sign in", sign_in_path %>
    <%= link_to "Sign up", sign_up_path %>
  <% end %>
EOF

insert -2, "config/environments/development.rb", <<-EOF
  config.action_mailer.default_url_options = { :host => "localhost:3000" }
EOF

insert -2, "config/environments/test.rb", <<-EOF
  config.action_mailer.default_url_options = { :host => "example.com" }
EOF

insert -1, "Rakefile", <<-EOF
  task(:default).clear
  task :default => [:spec, :cucumber]
EOF

git :init
git :add => '.'
git :commit => "-m 'Initial commit'"
