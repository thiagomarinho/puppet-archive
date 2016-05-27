wget_provider = Puppet::Type.type(:archive).provider(:wget)

RSpec.describe wget_provider do
  it_behaves_like 'an archive provider', wget_provider

  context 'without cache' do
    describe '#download' do
      let(:name)      { '/tmp/example.zip' }
      let(:resource)  { Puppet::Type::Archive.new(resource_properties) }
      let(:provider)  { wget_provider.new(resource) }
      let(:execution) { Puppet::Util::Execution }

      let(:default_options) do
        [
          'wget',
          'http://home.lan/example.zip',
          '-O',
          '/tmp/example.zip',
          '--max-redirect=5'
        ]
      end

      before do
        allow(FileUtils).to receive(:mv)
      end

      context 'no extra properties specified' do
        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip'
          }
        end

        it 'calls wget with input, output and --max-redirects=5' do
          expect(execution).to receive(:execute).with(default_options.join(' '))
          provider.download(name)
        end
      end

      context 'username specified' do
        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip',
            username: 'foo',
          }
        end

        it 'calls wget with default options and username' do
          expect(execution).to receive(:execute).with([default_options, '--user=foo'].join(' '))
          provider.download(name)
        end
      end

      context 'password specified' do
        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip',
            password: 'foo',
          }
        end

        it 'calls wget with default options and password' do
          expect(execution).to receive(:execute).with([default_options, '--password=foo'].join(' '))
          provider.download(name)
        end
      end

      context 'cookie specified' do
        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip',
            cookie: 'foo',
          }
        end

        it 'calls wget with default options and header containing cookie' do
          expect(execution).to receive(:execute).with([default_options, '--header="Cookie: foo"'].join(' '))
          provider.download(name)
        end
      end

      context 'proxy specified' do
        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip',
            proxy_server: 'https://home.lan:8080',
          }
        end

        it 'calls wget with default options and header containing cookie' do
          expect(execution).to receive(:execute).with([default_options, '--https_proxy=https://home.lan:8080'].join(' '))
          provider.download(name)
        end
      end
    end
  end

  context 'with cache' do
    describe '#download' do
      let(:name)      { '/tmp/example.zip' }
      let(:resource)  { Puppet::Type::Archive.new(resource_properties) }
      let(:execution) { Puppet::Util::Execution }
      let(:provider)  { wget_provider.new(resource) }

      let(:file_copy_options) do
        [
          'cp',
          '/var/cache/wget/example.zip',
          '/tmp/example.zip'
        ]
      end

      let(:wget_return) do
        <<-WGET
          Connecting to x.x.x.x:1234... connected.
          Proxy request sent, awaiting response... 200 OK
          Length: 153512879 (146M) [application/x-gzip]
          Saving to: '/var/cache/wget/example.zip'

               0K .......... .......... .......... .......... ..........  0%  398K 6m17s
              50K .......... .......... .......... .......... ..........  0% 1.17M 4m11s
          149900K .......... ....                                       100% 30.0M=76s

          2016-05-27 15:08:30 (1.92 MB/s) - '/var/cache/wget/example.zip' saved [153512879/153512879]
        WGET
      end

      context 'no extra properties specified' do
        let(:default_options) do
          [
            'wget',
            '-N',
            '-P',
            '/var/cache/wget',
            'http://home.lan/example.zip',
            '--max-redirect=5',
          ]
        end

        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/example.zip',
            cache: :enabled,
          }
        end

        it 'calls wget with input, output and --max-redirects=5' do
          expect(execution).to receive(:execute).with(default_options.join(' ')).and_return wget_return
          expect(execution).to receive(:execute).with(file_copy_options.join(' '))

          provider.download(name)
        end
      end

      context 'url with arguments' do
        let(:default_options) do
          [
            'wget',
            '-N',
            '-P',
            '/var/cache/wget',
            'http://home.lan/file?name=example',
            '--content-disposition',
            '--max-redirect=5',
          ]
        end

        let(:resource_properties) do
          {
            name: name,
            source: 'http://home.lan/file?name=example',
            cache: :enabled,
          }
        end

        it 'calls wget with input, output, --max-redirects=5 and --content-disposition' do
          expect(execution).to receive(:execute).with(default_options.join(' ')).and_return wget_return
          expect(execution).to receive(:execute).with(file_copy_options.join(' '))

          provider.download(name)
        end
      end
    end
  end
end
