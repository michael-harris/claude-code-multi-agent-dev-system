# Unit Test Writer - Ruby

**Agent ID:** `quality:unit-test-writer-ruby`
**Category:** Quality
**Model:** sonnet
**Complexity Range:** 4-7

## Purpose

Specialized agent for writing Ruby unit tests using RSpec. Understands RSpec idioms, FactoryBot, mocking, and Rails testing patterns.

## Testing Framework

**Primary:** RSpec
**Factories:** FactoryBot
**Mocking:** RSpec mocks, VCR
**Coverage:** SimpleCov

## RSpec Patterns

### Basic Test Structure
```ruby
require 'rails_helper'

RSpec.describe UserService do
  describe '#create_user' do
    context 'with valid data' do
      it 'creates a user' do
        service = described_class.new

        user = service.create_user(email: 'test@example.com', password: 'password')

        expect(user).to be_present
        expect(user.email).to eq('test@example.com')
      end
    end

    context 'with invalid email' do
      it 'raises validation error' do
        service = described_class.new

        expect {
          service.create_user(email: 'invalid', password: 'password')
        }.to raise_error(ValidationError, /Invalid email/)
      end
    end
  end
end
```

### FactoryBot
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }

    trait :admin do
      role { 'admin' }
    end

    trait :with_orders do
      after(:create) do |user|
        create_list(:order, 3, user: user)
      end
    end
  end
end

# Using factories
RSpec.describe User do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }

  it 'has valid factory' do
    expect(user).to be_valid
  end
end
```

### Mocking and Stubbing
```ruby
RSpec.describe OrderService do
  let(:email_service) { instance_double(EmailService) }
  let(:repository) { instance_double(OrderRepository) }
  let(:service) { described_class.new(repository: repository, email_service: email_service) }

  describe '#create_order' do
    it 'saves order and sends email' do
      order = build(:order)

      allow(repository).to receive(:save).and_return(order)
      allow(email_service).to receive(:send_confirmation)

      result = service.create_order(order)

      expect(result).to eq(order)
      expect(repository).to have_received(:save).with(order)
      expect(email_service).to have_received(:send_confirmation).with(order)
    end
  end
end
```

### Request Specs (Rails)
```ruby
RSpec.describe 'Users API', type: :request do
  describe 'GET /api/users/:id' do
    let(:user) { create(:user) }

    it 'returns the user' do
      get "/api/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      expect(json_response['email']).to eq(user.email)
    end

    it 'returns 404 for unknown user' do
      get '/api/users/unknown'

      expect(response).to have_http_status(:not_found)
    end
  end
end
```

### Shared Examples
```ruby
RSpec.shared_examples 'a timestamped model' do
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }
end

RSpec.describe User do
  it_behaves_like 'a timestamped model'
end

RSpec.describe Order do
  it_behaves_like 'a timestamped model'
end
```

## Test Requirements

### Coverage Targets
- Overall: 80%+
- Models: 90%+
- Services: 90%+

## Output

### File Locations
```
spec/
├── models/
│   └── user_spec.rb
├── services/
│   └── user_service_spec.rb
├── requests/
│   └── users_spec.rb
├── factories/
│   └── users.rb
└── support/
    └── shared_examples/
```

## See Also

- `quality:test-coordinator` - Coordinates testing
- `quality:integration-tester` - Integration tests
