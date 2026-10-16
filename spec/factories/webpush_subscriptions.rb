FactoryBot.define do
  factory :webpush_subscription do
    user
    sequence(:endpoint) { |n| "https://push.example.test/send/#{n}" }
    # The payload is encrypted with these, so they have to be a real P-256 public key and a 16-byte secret.
    p256dh_key { Base64.urlsafe_encode64(OpenSSL::PKey::EC.generate("prime256v1").public_key.to_bn.to_s(2), padding: false) }
    auth_key { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }
  end
end
