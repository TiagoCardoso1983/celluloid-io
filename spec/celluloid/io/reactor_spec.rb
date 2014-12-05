require 'spec_helper'

module Celluloid::IO::ReactorSpec
#  class Dad
#    include Celluloid::IO
#
#    def initialize
#      @sock = TCPSocket.new("localhost", 22)
#    end
#
#    def wiriwiri
#      begin
#        timeout(2) do
#          loop do
#            @sock.wait_readable
#          end
#        end
#      rescue
#        @sock.wait_readable
#      end
#    end
#  end

  describe Celluloid::IO::Reactor do
    let(:payload) { "balls" }
    it "shouldn't crash" do
      # Dad.new.wiriwir
      server = ::TCPServer.new example_addr, example_port
      thread = Thread.new { server.accept }
      socket = within_io_actor { Celluloid::IO::TCPSocket.new example_addr, example_port }
      peer = thread.value
      peer_thread = Thread.new { loop { peer << payload } }
      handle = false
      within_io_actor do
        begin
          timeout(2) do
            loop do
              socket.readpartial(2046)
            end
          end
        # rescuing timeout, ok. rescuing terminated error, is it ok? TODO: investigate
        rescue Celluloid::Task::TerminatedError, Timeout::Error
        ensure
          socket.readpartial(2046)
          handle = true
        end
      end
      expect(handle).to be_true

      server.close
      peer.close
      socket.close
    end
  end
end
