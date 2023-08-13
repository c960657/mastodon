# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaAttachment, :paperclip_processing do
  describe 'local?' do
    subject { media_attachment.local? }

    let(:media_attachment) { described_class.new(remote_url: remote_url) }

    context 'when remote_url is blank' do
      let(:remote_url) { '' }

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'when remote_url is present' do
      let(:remote_url) { 'remote_url' }

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  describe 'needs_redownload?' do
    subject { media_attachment.needs_redownload? }

    let(:media_attachment) { described_class.new(remote_url: remote_url, file: file) }

    context 'when file is blank' do
      let(:file) { nil }

      context 'when remote_url is present' do
        let(:remote_url) { 'remote_url' }

        it 'returns true' do
          expect(subject).to be true
        end
      end
    end

    context 'when file is present' do
      let(:file) { attachment_fixture('avatar.gif') }

      context 'when remote_url is blank' do
        let(:remote_url) { '' }

        it 'returns false' do
          expect(subject).to be false
        end
      end

      context 'when remote_url is present' do
        let(:remote_url) { 'remote_url' }

        it 'returns true' do
          expect(subject).to be false
        end
      end
    end
  end

  describe '#to_param' do
    let(:media_attachment) { Fabricate.build(:media_attachment, shortcode: shortcode, id: id) }

    context 'when media attachment has a shortcode' do
      let(:shortcode) { 'foo' }
      let(:id) { 123 }

      it 'returns shortcode' do
        expect(media_attachment.to_param).to eq shortcode
      end
    end

    context 'when media attachment does not have a shortcode' do
      let(:shortcode) { nil }
      let(:id) { 123 }

      it 'returns string representation of id' do
        expect(media_attachment.to_param).to eq id.to_s
      end
    end
  end

  shared_examples 'static 600x400 image' do |content_type, extension|
    after do
      media.destroy
    end

    it 'saves metadata' do
      expect(media.persisted?).to be true
      expect(media.file).to_not be_nil

      # completes processing
      expect(media.processing_complete?).to be true

      # sets type
      expect(media.type).to eq 'image'

      # sets content type
      expect(media.file_content_type).to eq content_type

      # sets file extension
      expect(media.file_file_name).to end_with extension

      # Rack::Mime (used by PublicFileServerMiddleware) recognizes file extension
      expect(Rack::Mime.mime_type(extension, nil)).to eq content_type

      # generates blurhash
      expect(media.blurhash.size).to eq 36
    end

    it 'saves original style' do
      # strips original file name
      expect(media.file_file_name).to_not start_with '600x400'

      # preserves original type and size
      expect(Marcel::MimeType.for(Pathname.new(media.file.path))).to eq content_type
      expect(FastImage.size(media.file.path(:original))).to eq [600, 400]

      # sets meta for original
      expect(media.file.meta['original']['width']).to eq 600
      expect(media.file.meta['original']['height']).to eq 400
      expect(media.file.meta['original']['aspect']).to eq 1.5
    end

    it 'saves small style' do
      # resizes but preserves type
      expect(Marcel::MimeType.for(Pathname.new(media.file.path))).to eq content_type
      expect(FastImage.size(media.file.path(:small))).to eq [588, 392]

      # sets meta for thumbnail
      expect(media.file.meta['small']['width']).to eq 588
      expect(media.file.meta['small']['height']).to eq 392
      expect(media.file.meta['small']['aspect']).to eq 1.5
    end
  end

  shared_examples 'animated 600x400 image' do
    after do
      media.destroy
    end

    it 'saves metadata' do
      expect(media.persisted?).to be true
      expect(media.file).to_not be_nil

      # completes processing
      expect(media.processing_complete?).to be true

      # sets type
      expect(media.type).to eq 'gifv'

      # sets content type
      expect(media.file_content_type).to eq 'video/mp4'

      # sets file extension
      expect(media.file_file_name).to end_with '.mp4'

      # generates blurhash
      expect(media.blurhash.size).to eq 36
    end

    it 'saves original style' do
      # transcodes to MP4
      expect(media.file.path).to end_with '.mp4'
      expect(Marcel::MimeType.for(Pathname.new(media.file.path))).to eq 'video/mp4'

      # sets meta for original
      expect(media.file.meta['original']['width']).to eq 600
      expect(media.file.meta['original']['height']).to eq 400
      expect(media.file.meta['original']['duration']).to eq 3
      expect(media.file.meta['original']['frame_rate']).to eq '1/1'
    end

    it 'saves small style' do
      # generates static PNG thumbnail
      expect(FastImage.type(media.file.path(:small))).to eq :png
      expect(media.file.path(:small)).to end_with '.png'
      expect(FastImage.animated?(media.file.path(:small))).to be false

      # scales image
      expect(FastImage.size(media.file.path(:small))).to eq [600, 400]

      # sets meta for thumbnail
      expect(media.file.meta['small']['width']).to eq 600
      expect(media.file.meta['small']['height']).to eq 400
      expect(media.file.meta['small']['aspect']).to eq 1.5
    end
  end

  describe 'jpeg' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.jpeg')) }

    it_behaves_like 'static 600x400 image', 'image/jpeg', '.jpeg'
  end

  describe 'png' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.png')) }

    it_behaves_like 'static 600x400 image', 'image/png', '.png'
  end

  describe 'gif' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.gif')) }

    it_behaves_like 'static 600x400 image', 'image/gif', '.gif'
  end

  describe 'webp' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.webp')) }

    it_behaves_like 'static 600x400 image', 'image/webp', '.webp'
  end

  describe 'avif' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.avif')) }

    it_behaves_like 'static 600x400 image', 'image/jpeg', '.jpeg'
  end

  describe 'heic' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400.heic')) }

    it_behaves_like 'static 600x400 image', 'image/jpeg', '.jpeg'
  end

  describe 'base64-encoded image' do
    let(:base64_attachment) { "data:image/jpeg;base64,#{Base64.encode64(attachment_fixture('600x400.jpeg').read)}" }
    let(:media) { Fabricate(:media_attachment, file: base64_attachment) }

    it_behaves_like 'static 600x400 image', 'image/jpeg', '.jpeg'
  end

  describe 'animated gif' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400-animated.gif')) }

    it_behaves_like 'animated 600x400 image'
  end

  describe 'animated png' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('600x400-animated.png')) }

    it_behaves_like 'animated 600x400 image'
  end

  describe 'ogg with cover art' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('boop.ogg')) }

    it 'sets correct file metadata' do
      expect(media.type).to eq 'audio'
      expect(media.file.meta['original']['duration']).to be_within(0.05).of(0.235102)
      expect(media.thumbnail.present?).to be true
      expect(media.file.meta['colors']['background']).to eq '#3088d4'
      expect(media.file_file_name).to_not eq 'boop.ogg'
    end
  end

  describe 'mp3 with large cover art' do
    let(:media) { Fabricate(:media_attachment, file: attachment_fixture('boop.mp3')) }

    it 'detects it as an audio file' do
      expect(media.type).to eq 'audio'
    end

    it 'sets meta for the duration' do
      expect(media.file.meta['original']['duration']).to be_within(0.05).of(0.235102)
    end

    it 'extracts thumbnail' do
      expect(media.thumbnail.present?).to be true
    end

    it 'gives the file a random name' do
      expect(media.file_file_name).to_not eq 'boop.mp3'
    end
  end

  it 'is invalid without file' do
    media = described_class.new

    expect(media.valid?).to be false
    expect(media).to model_have_error_on_field(:file)
  end

  describe 'size limit validation' do
    it 'rejects video files that are too large' do
      stub_const 'MediaAttachment::IMAGE_LIMIT', 100.megabytes
      stub_const 'MediaAttachment::VIDEO_LIMIT', 1.kilobyte
      expect { Fabricate(:media_attachment, file: attachment_fixture('attachment.webm')) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'accepts video files that are small enough' do
      stub_const 'MediaAttachment::IMAGE_LIMIT', 1.kilobyte
      stub_const 'MediaAttachment::VIDEO_LIMIT', 100.megabytes
      media = Fabricate(:media_attachment, file: attachment_fixture('attachment.webm'))
      expect(media.valid?).to be true
    end

    it 'rejects image files that are too large' do
      stub_const 'MediaAttachment::IMAGE_LIMIT', 1.kilobyte
      stub_const 'MediaAttachment::VIDEO_LIMIT', 100.megabytes
      expect { Fabricate(:media_attachment, file: attachment_fixture('attachment.jpg')) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'accepts image files that are small enough' do
      stub_const 'MediaAttachment::IMAGE_LIMIT', 100.megabytes
      stub_const 'MediaAttachment::VIDEO_LIMIT', 1.kilobyte
      media = Fabricate(:media_attachment, file: attachment_fixture('attachment.jpg'))
      expect(media.valid?).to be true
    end
  end
end
