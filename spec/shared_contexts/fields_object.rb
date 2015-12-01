# Fields
# ======
# A resource object's [attributes] and its [relationships] are collectively called
# its "[fields]".
shared_context 'fields object' do
  include JSONAPIObjects
  describe 'fields object' do
    context 'when containing `type` and `id`' do
      data = { type: 'stuff', id: '1' }
      it_should_behave_like 'an invalid jsonapi object', data
    end

    context 'when containing `type`' do
      data = { type: 'stuff' }
      it_should_behave_like 'an invalid jsonapi object', data
    end

    context 'when containing `id`' do
      data = { id: 1 }
      it_should_behave_like 'an invalid jsonapi object', data
    end
  end
end
