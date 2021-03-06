require 'spec_helper'

describe TimeSeriesMerge::Action::Merge do
  include_context 'shared context'

  let(:sources) { '/' }
  let(:destination_file_name) { 'destination_file_name' }

  before(:each) do
    allow(Dir).to receive(:glob).with(sources).and_return(file_list)
    subject.opts = opts.new(destination_file_name, sources)
  end

  it 'should return a list of files within the specified directory' do
    expect(subject.send(:files)).to eq(file_list)
  end

  context 'run' do
    let(:destination) { file.new([]) }
    let(:mode) { "#{File::RDONLY}:#{subject.class::INPUT_FILES_ENCODING}" }

    before(:each) do
      allow(File).to receive(:open).with(/#{file_list.split('|')}/, mode) do |file_name, mode, &block|
        input_file(file_name).push_records_to_block(&block)
      end
      allow(File).to receive(:open).with(destination_file_name, File::APPEND) do |file_name, mode, &block|
        destination.push_self_to_block(&block)
      end
      allow(File).to receive(:truncate).with(destination_file_name, subject.class::TRUNCATE_SIZE).and_return(nil)
      allow(File).to receive(:exists?).with(destination_file_name).and_return(nil)
    end

    it 'destination size equal 2' do
      subject.run
      expect(destination.records.size).to eq(2)
    end

    it 'destination file include merge files lines' do
      subject.run
      expect(destination.records).to include(*[file_lines[file1], file_lines[file2]])
    end
  end
end