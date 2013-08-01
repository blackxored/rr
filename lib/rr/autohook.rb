module RR
  class << self
    def autohook
      applicable_adapters.tap {|a| pp :adapters => a }.each { |adapter| adapter.load }
      if applicable_adapters.empty?
        puts "No adapters matched!" if RR.debug?
      end
    end
  end
end

RR.autohook
