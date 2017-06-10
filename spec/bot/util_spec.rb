require_relative '../../lib/bot/util'

RSpec.describe Bot::Util do
  describe '.is_admin?' do
    before do
      $admins = %w(U1234ASDF U4321TEST)
    end

    it 'is true when found' do
      expect(described_class.is_admin?('U4321TEST')).to be true
    end

    it 'is false when not found' do
      expect(described_class.is_admin?('U5678ZXCV')).to be false
    end
  end

  describe '.oxfordise' do
    context 'with a list size of 0' do
      it 'says "no one"' do
        expect(described_class.oxfordise([])).to eq 'no one'
      end
    end

    context 'with a list size of 1' do
      let(:list) { %w(asdf) }

      it 'produces correct output' do
        expect(described_class.oxfordise(list)).to eq list.first
      end
    end

    context 'with a list size of 2' do
      let(:list) { %w(asdf fdsa) }

      it 'produces correct output' do
        expect(described_class.oxfordise(list)).to eq 'asdf and fdsa'
      end
    end

    context 'with a list size of 3+' do
      let(:list) { %w(asdf fdsa test zxcv) }

      it 'produces correct output' do
        expect(described_class.oxfordise(list)).to eq 'asdf, fdsa, test, and zxcv'
      end
    end

    context 'with a different join word' do
      let(:list) { %w(asdf fdsa test zxcv) }
      let(:join_word) { 'or' }

      it 'produces correct output' do
        expect(described_class.oxfordise(list, join_word)).to eq 'asdf, fdsa, test, or zxcv'
      end
    end
  end

  describe '.tag_user' do
    context 'when given a user ID' do
      let(:user) { 'U1234ASDF' }

      it 'tags the user' do
        expect(described_class.tag_user(user)).to eq '<@U1234ASDF>'
      end
    end

    context 'when given a username' do
      let(:user) { 'some.user' }
      let(:uid) { 'U4321TEST' }

      it 'calls .user_id' do
        expect(described_class).to receive(:user_id).with(user).and_return(uid)

        described_class.tag_user(user)
      end

      it 'tags the user with their looked-up user ID' do
        allow(described_class).to receive(:user_id).with(user).and_return(uid)

        expect(described_class.tag_user(user)).to eq "<@#{uid}>"
      end
    end
  end

  describe 'private methods' do
    describe '.client' do
      it 'calls Bot::Client.init' do
        expect(Bot::Client).to receive(:new).with(no_args)

        described_class.send(:client)
      end
    end
  end
end
