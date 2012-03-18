require 'rubygems'
require 'rdoc/forum_joint.rb'
require 'factory_girl'

#this kinda sucks...
Sequel::Model.send(:alias_method, :save!, :save)

USERS=50
TOPICS=5
TAGS=3
REPLIES=[4,2]
FactoryGirl.define do 
  [:name,:title,:tag,:content].each do |seq|
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
    content
    _public_tags ''
    _private_tags ''
  end
  factory :private_message,:class => MR::PublicMessage do |n|
    user
    recipients ''
    title
    content
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
      FactoryGirl.create(:post,:user_id => u[:id])
    end
  end
end

