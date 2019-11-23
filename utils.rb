class ObjectFacade

  def self.get(key, facades)
    facades.detect do |facade|
      facade.respond_to?(:selector) && facade.selector.intern == key.intern
    end
  end

end

class Collector

  attr_accessor :storage, :facades, :processor

  def initialize(processor, facades)
    self.processor = processor
    self.facades = facades
    self.storage = {}.tap do |stor|
      facades.each {|f| stor.store(:"#{f::SCOPE}", [])}
    end
  end

  def run!
    self.processor.operations.lazy.each do |op|
      op.run!(self.storage)
    end
    self
  end

  def as_json
    self.storage.each_pair do |key, value|
      {}.tap do |data|
        data[key.downcase] = value.map(&:to_json)
      end
    end
  end

  def to_json(*options)
    as_json(*options).to_json(*options)
  end

end

class Processor

  attr_accessor :operations

  def initialize(operations=[])
    self.operations = operations
  end

end
