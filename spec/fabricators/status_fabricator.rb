# frozen_string_literal: true

Fabricator(:status) do
  account { Fabricate.build(:account) }
  text 'Lorem ipsum dolor sit amet'

  after_build do |status|
    status.uri ||= Faker::Internet.device_token unless status.account.local?
    status.language ||= 'en' if status.account.local?
  end
end
