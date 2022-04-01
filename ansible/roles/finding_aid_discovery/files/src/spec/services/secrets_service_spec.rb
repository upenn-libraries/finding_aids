# frozen_string_literal: true

require 'rails_helper'

describe SecretsService do
  describe '#lookup' do
    it 'raises an exception for unpermitted values' do
      expect { described_class.lookup(key: 'secret_key') }.to(
        raise_error(SecretsService::InvalidKeyError, /Non-permitted secret key provided/)
      )
    end

    it 'raises an exception for blank keys' do
      expect { described_class.lookup(key: '') }.to(
        raise_error(SecretsService::InvalidKeyError, /Non-permitted secret key provided/)
      )
    end
  end
end
