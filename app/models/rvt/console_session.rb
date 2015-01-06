module RVT
  # Manage and persist (in memory) RVT::Slave instances.
  class ConsoleSession
    include ActiveModel::Model

    # In-memory storage for the console sessions. Session preservation is
    # troubled on servers with multiple workers and threads.
    INMEMORY_STORAGE = {}

    # Base error class for ConsoleSession specific exceptions.
    #
    # Provides #to_json implementation, so all subclasses are JSON
    # serializable.
    class Error < StandardError
      def as_json(*)
        { error: to_s }
      end
    end

    # Raised when trying to find a session that is no longer in the in-memory
    # session storage or when the slave process exited.
    Unavailable = Class.new(Error)

    # Raised when an operation transition to an invalid state.
    Invalid = Class.new(Error)

    # Raised when a request doesn't know the slave process uid.
    Unauthorized = Class.new(Error)

    class << self
      # Finds a session by its pid.
      #
      # Raises RVT::ConsoleSession::Expired if there is no such session.
      def find(pid)
        INMEMORY_STORAGE[pid.to_i] or raise Unavailable, 'Session unavailable'
      end

      # Finds a session by its pid.
      #
      # Raises RVT::ConsoleSession::Expired if there is no such session.
      # Raises RVT::ConsoleSession::Unauthorized if uid doesn't match.
      def find_by_pid_and_uid(pid, uid)
        find(pid).tap do |console_session|
          raise Unauthorized if console_session.uid != uid
        end
      end

      # Creates an already persisted consolse session.
      #
      # Use this method if you need to persist a session, without providing it
      # any input.
      def create
        new.persist
      end
    end

    def initialize
      @slave = Slave.new
    end

    # Explicitly persist the model in the in-memory storage.
    def persist
      INMEMORY_STORAGE[pid] = self
    end

    # Returns true if the current session is persisted in the in-memory storage.
    def persisted?
      self == INMEMORY_STORAGE[pid]
    end

    # Returns an Enumerable of all key attributes if any is set, regardless if
    # the object is persisted or not.
    def to_key
      [pid] if persisted?
    end

    private

    def delegate_and_call_slave_method(name, *args, &block)
      # Cache the delegated method, so we don't have to hit #method_missing
      # on every call.
      define_singleton_method(name) do |*inner_args, &inner_block|
        begin
          @slave.public_send(name, *inner_args, &inner_block)
        rescue ArgumentError => exc
          raise Invalid, exc
        rescue Slave::Closed => exc
          raise Unavailable, exc
        end
      end

      # Now call the method, since that's our most common use case. Delegate
      # the method and than call it.
      public_send(name, *args, &block)
    end

    def method_missing(name, *args, &block)
      if @slave.respond_to?(name)
        delegate_and_call_slave_method(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_all = false)
      @slave.respond_to?(name) or super
    end
  end
end
