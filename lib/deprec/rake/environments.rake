# This coolness is from Chris Wanstrath
# http://errtheblog.com/posts/31-rake-around-the-rosie

%w(development production staging testing).each do |env|
  desc "Runs the following task in the #{env} environment" 
  task env.to_sym do
    RAILS_ENV = ENV['RAILS_ENV'] = env
  end
end
