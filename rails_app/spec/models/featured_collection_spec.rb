# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeaturedCollection, type: :model do
  describe 'validations' do
    describe 'title_must_exist_for_repository' do
      before do
        allow(RepositoryQueries).to receive(:titles_by_repository).and_return(
          'Test Repo' => ['Valid Title', 'Another Valid Title']
        )
      end

      it 'is valid when the title exists at the repository' do
        fc = described_class.new(title: 'Valid Title', repository: 'Test Repo')
        expect(fc).to be_valid
      end

      it 'is invalid when the title does not exist at the repository' do
        fc = described_class.new(title: 'Missing Title', repository: 'Test Repo')
        expect(fc).not_to be_valid
        expect(fc.errors[:title]).to include('is not a collection at the selected repository')
      end
    end

    it 'requires a title' do
      fc = described_class.new(title: nil, repository: 'Test Repo')
      expect(fc).not_to be_valid
      expect(fc.errors[:title]).to include("can't be blank")
    end

    it 'requires a repository' do
      fc = described_class.new(title: 'Some Title', repository: nil)
      expect(fc).not_to be_valid
      expect(fc.errors[:repository]).to include("can't be blank")
    end
  end
end
