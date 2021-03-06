require 'json'
require 'rom-repository'

RSpec.describe ROM::HTTP::Relation do
  subject(:users) { container.relation(:users).by_id(id).filter(params) }

  include_context 'setup'

  let(:relation) do
    Class.new(ROM::HTTP::Relation) do
      schema(:users) do
        attribute :id, ROM::Types::Int
        attribute :name, ROM::Types::String
      end

      def by_id(id)
        append_path(id.to_s)
      end

      def filter(params)
        with_params(params)
      end
    end
  end

  let(:response) { tuples.to_json }
  let(:tuples) { [{ id: 1337, name: 'John' }] }
  let(:id) { 1337 }
  let(:params) { { filters: { first_name: 'John' } } }

  let(:dataset) do
    ROM::HTTP::Dataset.new(
      {
        uri: uri,
        headers: headers,
        request_handler: request_handler,
        response_handler: response_handler,
        name: :users
      },
      path: "users/#{id}",
      params: params
    )
  end

  before do
    configuration.register_relation(relation)

    allow(request_handler).to receive(:call).and_return(response)
    allow(response_handler).to receive(:call).and_return(tuples)
  end

  it 'returns relation tuples' do
    expect(users.to_a).to eql(tuples)

    expect(request_handler).to have_received(:call).with(dataset).once
    expect(response_handler).to have_received(:call).with(response, dataset).once
  end

  context 'using a repo' do
    let(:repo) do
      Class.new(ROM::Repository) { relations :users }.new(container)
    end

    it 'returns structs' do
      user = repo.users.by_id(1337).filter(params).one

      expect(user.id).to be(1337)
      expect(user.name).to eql('John')

      expect(request_handler).to have_received(:call).with(dataset).once
      expect(response_handler).to have_received(:call).with(response, dataset).once
    end
  end
end
