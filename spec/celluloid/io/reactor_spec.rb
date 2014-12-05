require 'spec_helper'

module Celluloid::IO::ReactorSpec
  class Dad
    include Celluloid::IO

    def initialize
      @sock = TCPSocket.new("localhost", 22)
    end

    def wiriwiri
      begin
        timeout(2) do
          loop do
            @sock.wait_readable
          end
        end
      rescue
        @sock.wait_readable
      end
    end
  end

  describe Celluloid::IO::Reactor do
    it "shouldn't crash" do
      Dad.new.wiriwiri
    end
  end
end
