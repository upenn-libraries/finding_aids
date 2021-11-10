describe 'Blacklight' do
  it 'loads the homepage with no solr query or results' do
    get '/'
    expect(response.body).to include 'Welcome!'
  end
  it 'performs a Solr query if a q param is present' do
    get '/?q=cheese'
    expect(response.body).to include 'No results found for your search'
  end
end
