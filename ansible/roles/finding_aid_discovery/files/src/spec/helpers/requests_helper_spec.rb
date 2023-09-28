# frozen_string_literal: true

require 'rails_helper'

describe RequestsHelper do
  describe '.containers_from_params' do
    let(:params) { ActionController::Parameters.new(params_hash) }
    let(:result) do
      obj = Object.new
      obj.extend(described_class)
      helper.containers_from_params(params)
    end

    context 'with one container' do
      let(:params_hash) do
        { c: { 'Box_1' => '1' } }
      end

      it 'returns expected values' do
        expect(result).to eq [{ value: 'Box 1', barcode: nil }]
      end
    end

    context 'with multiple containers and no barcodes' do
      let(:params_hash) do
        { c: { 'Box_1' => '1', 'Box_2' => '1' } }
      end

      it 'returns expected values' do
        expect(result).to eq [{ value: 'Box 1', barcode: nil }, { value: 'Box 2', barcode: nil }]
      end
    end

    context 'with multiple containers and barcodes' do
      let(:params_hash) do
        { c: { 'Box_1_111111111' => '1', 'Box_2_222222222' => '1' } }
      end

      it 'returns expected values' do
        expect(result).to eq [{ value: 'Box 1', barcode: '111111111' }, { value: 'Box 2', barcode: '222222222' }]
      end
    end

    context 'with issues within a container' do
      let(:params_hash) do
        { c: { 'Box_1' => { 'Folder_2' => '1' } } }
      end

      it 'returns expected values' do
        expect(result).to eq [{ value: 'Box 1: Folder 2', barcode: nil }]
      end
    end
  end
end