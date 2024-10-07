# frozen_string_literal: true

require 'rails_helper'

describe DockerSecrets do
  describe '#lookup' do
    it 'raises an exception for blank keys' do
      expect { described_class.lookup('') }.to(
        raise_error(DockerSecrets::InvalidKeyError, /Lookup key is blank/)
      )
    end
  end

  describe '#lookup!' do
    it 'raises an exception when a key is not found' do
      expect { described_class.lookup!(:invalid_key) }.to(
        raise_error(DockerSecrets::InvalidKeyError, /Docker secret not found/)
      )
    end
  end
end
