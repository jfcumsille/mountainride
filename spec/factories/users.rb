FactoryBot.define do
  factory :user do
    first_name { "Juan" }
    last_name { "Pérez" }
    sequence(:email) { |n| "user#{n}@example.com" }
    phone { "56987654321" }
    password { "password123" }
    password_confirmation { "password123" }
  end
end
