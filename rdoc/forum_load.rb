#require 'rubygems'
require 'rdoc/forum_joint.rb'
require 'factory_girl'

#this kinda sucks...
Sequel::Model.send(:alias_method, :save!, :save)

USERS=5
TOPICS=40
TAGS=3
REPLIES=4
FactoryGirl.define do 
  [:name,:title,:tag,:message].each do |seq|
    sequence seq do |n|
      "#{seq.to_s}#{n}"
    end
  end
  factory :user,:class => MR::User,:aliases => [:author,:recipient] do |n|
    name
    password 'asdfasdf'
    confirm_password 'asdfasdf'
  end
  factory :post,:class => MR::PublicMessage do |n|
    user
    title
    message
    _public_tags ''
    _private_tags ''
  end
  factory :private_message,:class => MR::PrivateMessage do |n|
    user
    recipients ''
    title
    message
    _private_tags ''
  end
  factory :public_tag,:class => MR::PublicTag do |n|
    tag
  end
  factory :private_tag,:class => MR::PrivateTag do |n|
    user
    tag
  end
end
USERS.times do 
  FactoryGirl.create(:user) do |u|
    $request={:user => u}
    TOPICS.times do 
      FactoryGirl.create(:post,:user_id => u[:id],:_public_tags => (1 .. TAGS).to_a.map{|i| "tag#{i}"}.join(','))
    end
  end
end
REPLIES.times do
  MR::PublicMessage.all.each do |m|
    rep=m.reply
    rep.user_id=m[:id].modulo(USERS) + 1
    rep.message='asdfasdfasdfasdfasdfasdf'
    rep.save
  end
end

