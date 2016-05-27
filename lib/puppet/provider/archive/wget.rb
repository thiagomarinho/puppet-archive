Puppet::Type.type(:archive).provide(:wget, parent: :ruby) do
  commands wget: 'wget', cp: 'cp'

  def download(filepath)
    Wget::Strategy.get(self).download filepath
  end
end

module Wget
  class Strategy
    def self.get(provider)
      if provider.resource[:cache] == :enabled
        return Cache.new(provider)
      else
        return NoCache.new(provider)
      end
    end

    def initialize(provider)
      @provider = provider
    end

    def exec_wget
      add_default_params
      command 'wget', @params
    end

    def add_default_params
      @params ||= []
      @params << '--max-redirect=5'
      @params += @provider.optional_switch(@provider.resource[:username], ['--user=%s'])
      @params += @provider.optional_switch(@provider.resource[:password], ['--password=%s'])
      @params += @provider.optional_switch(@provider.resource[:cookie], ['--header="Cookie: %s"'])
      @params += @provider.optional_switch(@provider.resource[:proxy_server], ["--#{@provider.resource[:proxy_type]}_proxy=#{@provider.resource[:proxy_server]}"])
    end

    def command program, params
      command = "#{program} #{params.join(' ')}"
      # NOTE:
      # Do NOT use wget(params) until https://tickets.puppetlabs.com/browse/PUP-6066 is resolved.
      Puppet::Util::Execution.execute(command)
    end
  end

  class Cache < Strategy
    def download(filepath)
      @params = [
        '-N',
        '-P',
        '/var/cache/wget',
        @provider.resource[:source],
      ]

      @params << '--content-disposition' if @provider.resource[:source].include?('?')

      wget_output = exec_wget
      @provider.debug "wget_output: #{wget_output}"
      tempfilepath = %r{/var/cache/wget/.*'}.match(wget_output).to_s.delete("'")

      command 'cp', [tempfilepath, filepath]
    end
  end

  class NoCache < Strategy
    def download(filepath)
      @params = [
        @provider.resource[:source],
        '-O',
        filepath,
      ]

      exec_wget
    end
  end
end