require "nio"

module Celluloid
  module IO
    # React to external I/O events. This is kinda sorta supposed to resemble the
    # Reactor design pattern.
    class Reactor
      extend Forwardable

      # Unblock the reactor (i.e. to signal it from another thread)
      def_delegator :@selector, :wakeup
      # Terminate the reactor
      def_delegator :@selector, :close, :shutdown

      def initialize
        @selector = NIO::Selector.new
      end

      # Wait for the given IO object to become readable
      def wait_readable(io, timeout=nil)
        wait io, :r, timeout
      end

      # Wait for the given IO object to become writable
      def wait_writable(io, timeout=nil)
        wait io, :w, timeout
      end

      # Wait for the given IO operation to complete
      def wait(io, set, timeout=nil)
        # zomg ugly type conversion :(
        unless io.is_a?(::IO) || io.is_a?(OpenSSL::SSL::SSLSocket)
          if io.respond_to? :to_io
            io = io.to_io
          elsif ::IO.respond_to? :try_convert
            io = ::IO.try_convert(io)
          end

          fail TypeError, "can't convert #{io.class} into IO" unless io.is_a?(::IO)
        end

        monitor = @selector.register(io, set)
        monitor.value = Task.current

        begin
          # this condition is actually superflous; Timeout.timeout method signature is not respected
          # by Celluloid:Actor#timeout; Timeout.timeout has arity 2 and can receive nil; the first one
          # is already addressed in a PR in github
          if timeout 
            Thread.current[:celluloid_actor].send(:timeout, timeout) { Task.suspend :iowait }
          else
            Task.suspend :iowait
          end
        ensure
          # In all cases we want to ensure that the monitor is closed once we
          # have woken up. However, in some cases, the monitor is already
          # invalid, e.g. in the case that we are terminating. We catch this
          # case explicitly.
          monitor.close unless monitor.closed?
        end
      end

      # Run the reactor, waiting for events or wakeup signal
      def run_once(timeout = nil)
        @selector.select(timeout) do |monitor|
          task = monitor.value

          if task.running?
            task.resume
          else
            Logger.warn("reactor attempted to resume a dead task")
          end
        end
      end
    end
  end
end
