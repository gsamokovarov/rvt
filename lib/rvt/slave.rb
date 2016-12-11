module RVT
  # = Slave\ Process\ Wrapper
  #
  # Creates and communicates with slave processes.
  #
  # The communication happens through an input with attached psuedo-terminal.
  # All of the communication is done in asynchronous way, meaning that when you
  # send input to the process, you have get the output by polling for it.
  class Slave
    # Different OS' and platforms raises different errors when trying to read
    # on output end of a closed process.
    READING_ON_CLOSED_END_ERRORS = [ Errno::EIO, EOFError ]

    # Raised when trying to read from a closed (exited) process.
    Closed = Class.new(IOError)

    # The slave process id.
    attr_reader :pid

    # Unique identifier for each slave process.
    attr_reader :uid

    def initialize(command = RVT.config.command, options = {})
      # Windows doesn't have PTY, requiring it at the top level will fail the
      # whole program execution.
      require 'pty'
      require 'io/console'

      @uid = SecureRandom.hex(16)

      using_term(options[:term] || RVT.config.term) do
        @output, @input, @pid = PTY.spawn(command.to_s)
      end

      configure(options)
    end

    # Configure the psuedo terminal properties.
    #
    # Options:
    #   :width  The width of the terminal in number of columns.
    #   :height The height of the terminal in number of rows.
    #
    # If any of the width or height is missing (or zero), the terminal size
    # won't be set.
    def configure(options = {})
      dimentions = options.values_at(:height, :width).collect(&:to_i)
      begin
        @input.winsize = dimentions
      rescue TypeError
        @input.winsize = [*dimentions, 0, 0]
      end if dimentions.none?(&:zero?)
    end

    # Sends input to the slave process STDIN.
    #
    # Returns immediately.
    def send_input(input)
      raise ArgumentError if input.nil? or input.try(:empty?)
      input.each_char { |char| @input.putc(char) }
    end

    # Returns whether the slave process has any pending output in +wait+
    # seconds.
    #
    # By default, the +timeout+ follows +config.rvt.timeout+. Usually,
    # it is zero, making the response immediate.
    def pending_output?(timeout = RVT.config.timeout)
      # JRuby's select won't automatically coerce ActiveSupport::Duration.
      !!IO.select([@output], [], [], timeout.to_i)
    end

    # Gets the pending output of the process.
    #
    # The pending output is read in an non blocking way by chunks, in the size
    # of +chunk_len+. By default, +chunk_len+ is 49152 bytes.
    #
    # Returns +nil+, if there is no pending output at the moment. Otherwise,
    # returns the output that hasn't been read since the last invocation.
    #
    # Raises Errno:EIO on closed output stream. This can happen if the
    # underlying process exits.
    def pending_output(chunk_len = 49152)
      # Returns nil if there is no pending output.
      return unless pending_output?

      pending = String.new
      while chunk = @output.read_nonblock(chunk_len)
        pending << chunk
      end
      pending.force_encoding('UTF-8')
    rescue IO::WaitReadable
      pending.force_encoding('UTF-8')
    rescue
      raise Closed if READING_ON_CLOSED_END_ERRORS.any? { |exc| $!.is_a?(exc) }
    end

    # Dispose the underlying process, sending +SIGTERM+.
    #
    # After the process is disposed, it is detached from the parent to prevent
    # zombies.
    #
    # If the process is already disposed an Errno::ESRCH will be raised and
    # handled internally. If you want to handle Errno::ESRCH yourself, pass
    # +{raise: true}+ as options.
    #
    # Returns a thread, which can be used to wait for the process termination.
    def dispose(options = {})
      dispose_with(:SIGTERM, options)
    end

    # Dispose the underlying process, sending +SIGKILL+.
    #
    # After the process is disposed, it is detached from the parent to prevent
    # zombies.
    #
    # If the process is already disposed an Errno::ESRCH will be raised and
    # handled internally. If you want to handle Errno::ESRCH yourself, pass
    # +{raise: true}+ as options.
    #
    # Returns a thread, which can be used to wait for the process termination.
    def dispose!(options = {})
      dispose_with(:SIGKILL, options)
    end

    private

    LOCK = Mutex.new

    def using_term(term)
      if term.nil?
        yield
      else
        LOCK.synchronize do
          begin
            (previous_term, ENV['TERM'] = ENV['TERM'], term) and yield
          ensure
            ENV['TERM'] = previous_term
          end
        end
      end
    end

    def dispose_with(signal, options = {})
      Process.kill(signal, @pid)
      Process.detach(@pid)
    rescue Errno::ESRCH
      raise if options[:raise]
    end
  end
end
