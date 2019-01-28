require 'sidekiq'
require_relative '../../src/jobs/after_install_job'

task :recreate_webhooks do
  Shop.find_each { |shop| recreate_webhooks(shop) }
end

task :remove_old_webhooks do
  Shop.find_each { |shop| remove_old_webhooks(shop) }
end

def recreate_webhooks(shop)
  puts "Checking shop: #{shop.name}"

  api_session = ShopifyAPI::Session.new(shop.name, shop.token)
  ShopifyAPI::Base.activate_session(api_session)

  # this will raise if the call fails and the job won't get queued
  shopify_shop = ShopifyAPI::Shop.current

  AfterInstallJob.new.perform(shop.name)
rescue => e
  puts "Error: #{e} for shop: #{shop.name}"
end

def remove_old_webhooks(shop)
  puts "Checking shop: #{shop.name}"

  api_session = ShopifyAPI::Session.new(shop.name, shop.token)
  ShopifyAPI::Base.activate_session(api_session)

  paid_webhooks = ShopifyAPI::Webhook.where(topic: 'orders/paid')
  paid_webhooks.each do |webhook|
    ShopifyAPI::Webhook.delete(webhook.id)
  end
rescue => e
  puts "Error deleting webhooks for shop #{shop.name} error: #{e}"
end