# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 2.3.0', '< 2.5.0'

gem 'rails', '~> 5.1.0'
gem 'pg', '~> 0.20'
gem 'puma', '~> 3.8'
gem 'sass-rails', '~> 5.0'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'uglifier'

gem 'bootsnap'
gem 'mastodon-api', require: 'mastodon'
gem 'twitter', git: 'https://github.com/sferik/twitter'
gem 'devise', '~> 4.2'
gem 'omniauth-twitter'
gem 'omniauth-mastodon', '>= 0.9.2'
gem 'hamlit-rails', '~> 0.2'
gem 'fast_blank', '~> 1.0'

group :development, :test do
  gem 'pry'
  gem 'dotenv-rails', '~> 2.2'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'better_errors', '~> 2.1'
end

group :production do
  gem 'lograge', '~> 0.5'
  gem 'rails_12factor'
end
