module Traversable

  # Follow or create the path specified by the signature and assign
  # the value as a terminating leaf node.
  #  
  #  h.set([:a, :b, :c], "This is a retrievable value")
  #
  def set(sig, val)
    raise ArgumentError if sig.empty?
    create_path(sig) do |node, key|
      node[key] = val
    end
  end

  def reduce(sig, base=0)
    create_path(sig) do |node, key|
      node[key] = base unless node.has_key?(key)
      node[key] = yield node[key]
    end
  end

  def increment(sig, val=1)
    val = yield if block_given?
    create_path(sig) do |node, key|
      if node.has_key?(key)
        node[key] = node[key] + val
      else
        node[key] = val
      end
    end
  end

   # Usage:
  # a = ht.reducer([:a, :b, :c], 0) {|acc, v| acc + v }
  # a[1]
  def reducer(sig, base, &block)
    p = nil
    create_path(sig) do |node, key|
      unless node.has_key?(key)
        node[key] = base
      end
      p = lambda do |newval|
        node[key] = block.call(node[key], newval)
      end
    end
    p
  end

  def sum(*args)
    out = 0
    retrieve(*args) { |v| out += v }
    out
  end

  def count(*args)
    args = args + [:_count]
    sum(*args)
  end

  def unique(*args)
    out = 0
    filter(*args) { |v| out += v.size }
    out
  end

  # like retrieve, but will return any kind of node
  def filter(*sig)
    results = []
    search(sig) do |node|
      results << node
      yield(node) if block_given?
    end
    results
  end

  # Given a signature array, attempt to retrieve matching leaf values.
  def retrieve(*sig)
    results = []
    search(sig) do |node|
      results << node unless node.respond_to?(:children)
      yield(node) if block_given?
    end
    results
  end

  # Generic tree search method
  def search(sig)
    current_nodes = [self]

    while !current_nodes.empty?
      next_nodes = []
      matcher = sig.shift
      if matcher
        current_nodes.each do |node|
          if node.respond_to?(:children)
            next_nodes += node.children(matcher)
          end
        end
      else
        current_nodes.each {|n| yield(n) }
      end
      current_nodes = next_nodes
    end
  end

  def traverse
    current_nodes = [self]
    while !current_nodes.empty?
      next_nodes = []
      current_nodes.each do |node|
        if node.respond_to?(:children)
          next_nodes += node.children(true)
          yield(node)
        end
      end

      current_nodes = next_nodes
    end
  end

end

class HashTree < Hash
  include Traversable

  # Override the constructor to provide a default_proc
  # NOTE: there's a better way to do this in 1.9.2, it seems.
  # See Hash#default_proc=
  def self.new()
    hash = Hash.new { |h,k| h[k] = HashTree.new }
    super.replace(hash)
  end

  def self.[](hash)
    ht = self.new
    ht << hash
    ht
  end

  def _dump(depth)
    h = Hash[self]
    h.delete_if {|k,v| v.is_a? Proc }
    Marshal.dump(h)
  end

  def self._load(*args)
    h = Marshal.load(*args)
    ht = self.new
    ht.replace(h)
    ht
  end

  # Follow the path specified, creating new nodes where necessary.
  # Returns the value at the end of the path. If a block is supplied,
  # it will be called with the last node and the last key as parameters,
  # analogous to Hash.new's default proc. This is necessary to allow
  # setting a value at the end of the path.  See the implementation of #insert.
  def create_path(sig)
    final_key = sig.pop
    hash = self
    sig.each do |a|
      hash = hash[a]
    end
    yield(hash, final_key) if block_given?
    hash[final_key]
  end

  # Attempt to retrieve the value at the end of the path specified,
  # without creating new nodes.  Returns nil on failure.
  # TODO: consider whether splatting the signature is wise.
  def find(sig)
    stage = self
    sig.each do |a|
      if stage.has_key?(a)
        stage = stage[a]
      else
        return nil
      end
    end
    stage
  end

  def remove(*sig)
    stage = self
    s2 = sig.slice(0..-2)
    s2.each do |a|
      if stage.has_key?(a)
        stage = stage[a]
      else
        return nil
      end
    end
    stage.delete(sig.last)
  end

  def children(matcher=true)
    next_keys = self.keys.select do |key|
      match?(matcher, key)
    end
    self.values_at(*next_keys)
  end

  def +(other)
    out = HashTree.new
    _plus(other, out)
    out
  end

  def _plus(ht2, out)
    self.each do |k1,v1|
      v1 = v1.respond_to?(:dup) ? v1 : v1.dup
      if ht2.has_key?(k1)
        v2 = ht2[k1]
        if v1.respond_to?(:_plus)
          out[k1] = v1
          v1._plus(v2, out[k1])
        elsif v2.respond_to?(:_plus)
          raise ArgumentError,
            "Can't merge leaf with non-leaf:\n#{v1.inspect}\n#{v2.inspect}"
        else
          if v2.is_a?(Numeric) && v1.is_a?(Numeric)
            out[k1] = v1 + v2
          else
            out[k1] = [v1, ht2[k1]]
          end
        end
      else
        # should anything happen here?
      end
    end
    ht2.each do |k,v|
      if self.has_key?(k)
        # should anything happen here?
      else
        v = v.respond_to?(:dup) ? v : v.dup
        out[k] = v
      end
    end
  end

  def <<(other)
    other.each do |k,v1|
      if self.has_key?(k)
        v2 = self[k]
        if v1.respond_to?(:has_key?) && v2.respond_to?(:has_key?)
          v2 << v1
        elsif v1.is_a?(Numeric) && v2.is_a?(Numeric)
          self[k] = v1 + v2
        else
          raise ArgumentError,
            "Can't merge leaf with non-leaf:\n#{v1.inspect}\n#{v2.inspect}"
        end
      else
        if v1.respond_to?(:has_key?)
          self[k] << v1
        else
          self[k] = v1
        end
      end
    end
  end

  def match?(val, key)
    case val
    when true
      true
    when String, Symbol
      key == val
    when Regexp
      key =~ val
    when Proc
      val.call(key)
    when nil
      false
    else
      raise ArgumentError, "Unexpected matcher type: #{val.inspect}"
    end
  end

  def each_path(stack=[], &block)
    self.each do |k, v|
      stack.push(k)
      if v.respond_to?(:each_path)
        v.each_path(stack, &block)
      else
        block.call(stack, v)
      end
      stack.pop
    end
  end

  def paths
    out = []
  end

  def each_leaf(stack=[], &block)
    self.each do |k,v|
      stack.push(k)
      if v.respond_to?(:each_leaf)
        v.each_leaf(stack, &block)
      else
        block.call(v)
      end
      stack.pop
    end
  end

end





