# frozen_string_literal: true

# methods to mock Aeon web service responses
module AeonResponseMocks
  # @param [Symbol] type
  # @param [Hash] body_hash
  def successful_single_request_penn(type = :penn, body_hash:)
    stub_request(:post, auth_url(type))
      .with(body: body_hash)
      .to_return(
        status: 200,
        body: html_file_content('successful_single_request_response.html')
      )
  end

  # @param [String] filename
  # @return [String]
  def html_file_content(filename)
    File.read(
      File.join(File.dirname(__FILE__), '../fixtures/aspace_html', filename)
    )
  end

  # @param [Symbol] type
  # @return [String]
  def auth_url(type)
    AeonService.submit_url type
  end
end
