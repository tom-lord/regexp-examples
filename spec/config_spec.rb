RSpec.describe RegexpExamples::Config do
  describe 'max_repeater_variance' do
    context 'as a passed parameter' do
      it 'with low limit' do
        expect(/[A-Z]/.examples(max_results_limit: 5))
          .to match_array %w[A B C D E]
      end
      it 'with (default) high limit' do
        expect(/[ab]{14}/.examples.length)
          .to be <= 10_000 # NOT 2**14 == 16384, because it's been limited
      end
      it 'with (custom) high limit' do
        expect(/[ab]{14}/.examples(max_results_limit: 20_000).length)
          .to eq 16_384 # NOT 10000, because it's below the limit
      end
      it 'for boolean or groups' do
        expect(/[ab]{3}|[cd]{3}/.examples(max_results_limit: 10).length)
          .to eq 10
      end
      it 'for case insensitive examples' do
        expect(/[ab]{3}/i.examples(max_results_limit: 10).length)
          .to be <= 10
      end
      it 'for range repeaters' do
        expect(/[ab]{2,3}/.examples(max_results_limit: 10).length)
          .to be <= 10 # NOT 4 + 8 = 12
      end
      it 'for backreferences' do
        expect(/([ab]{3})\1?/.examples(max_results_limit: 10).length)
          .to be <= 10 # NOT 8 * 2 = 16
      end
      it 'for a complex pattern' do
        expect(/(a|[bc]{2})\1{1,3}/.examples(max_results_limit: 14).length)
          .to be <= 14 # NOT (1 + 4) * 3 = 15
      end
    end

    context 'as a global setting' do
      before do
        @original = RegexpExamples::Config.max_results_limit
        RegexpExamples::Config.max_results_limit = 5
      end
      after do
        RegexpExamples::Config.max_results_limit = @original
      end

      it 'sets limit without passing explicitly' do
        expect(/[A-Z]/.examples)
          .to match_array %w[A B C D E]
      end
    end
  end # describe 'max_results_limit'

  describe 'max_repeater_variance' do
    context 'as a passed parameter' do
      it 'with a larger value' do
        expect(/a+/.examples(max_repeater_variance: 5))
          .to match_array %w[a aa aaa aaaa aaaaa aaaaaa]
      end
      it 'with a lower value' do
        expect(/a{4,8}/.examples(max_repeater_variance: 0))
          .to eq %w[aaaa]
      end
    end

    context 'as a global setting' do
      before do
        @original = RegexpExamples::Config.max_repeater_variance
        RegexpExamples::Config.max_repeater_variance = 5
      end
      after do
        RegexpExamples::Config.max_repeater_variance = @original
      end

      it 'sets limit without passing explicitly' do
        expect(/a+/.examples)
          .to match_array %w[a aa aaa aaaa aaaaa aaaaaa]
      end
    end
  end # describe 'max_repeater_variance'

  describe 'max_group_results' do
    context 'as a passed parameter' do
      it 'with a larger value' do
        expect(/\d/.examples(max_group_results: 10))
          .to match_array %w[0 1 2 3 4 5 6 7 8 9]
      end
      it 'with a lower value' do
        expect(/\d/.examples(max_group_results: 3))
          .to match_array %w[0 1 2]
      end
    end

    context 'as a global setting' do
      before do
        @original = RegexpExamples::Config.max_group_results
        RegexpExamples::Config.max_group_results = 10
      end
      after do
        RegexpExamples::Config.max_group_results = @original
      end

      it 'sets limit without passing explicitly' do
        expect(/\d/.examples)
          .to match_array %w[0 1 2 3 4 5 6 7 8 9]
      end
    end
  end # describe 'max_group_results'

  describe 'thread safety' do
    it 'uses thread-local global config values' do
      thread = Thread.new do
        RegexpExamples::Config.max_group_results = 1
        expect(/\d/.examples).to eq %w[0]
      end
      sleep 0.1 # Give the above thread time to run
      expect(/\d/.examples).to eq %w[0 1 2 3 4]
      thread.join
    end

    it 'uses thread-local block config values' do
      thread = Thread.new do
        RegexpExamples::Config.with_configuration(max_group_results: 1) do
          expect(/\d/.examples).to eq %w[0]
          sleep 0.2 # Give the below thread time to run while this block is open
        end
      end
      sleep 0.1 # Give the above thread time to run
      expect(/\d/.examples).to eq %w[0 1 2 3 4]
      thread.join
    end
  end # describe 'thread safety'
end
