class MemoryModel < OpenStruct

  @@db = {}
  @@types = {}

  def initialize(hash)
    @@types[self.class] ||= {}
    hash = resolve_types(symbolize_keys(hash))
    super(hash)
  end

  def id
    object_id
  end

  def type
    @table[:type]
  end

  def update(hash)
    @table.merge!(resolve_types(symbolize_keys(hash)))
    self
  end

  def destroy
    self.class.all.delete_if { |b| b.id == id }
  end

  def self.find(id)
    all.find { |r| r.id == id.to_i }
  end

  def self.create(hash = {})
    all << new(hash)
    all[-1]
  end

  def self.all
    @@db[self] ||= []
    @@db[self]
  end
  
  def self.first
    all.first
  end

  def self.delete_all
    all.clear
  end

  def self.count
    all.size
  end

  def self.attribute(attribute, type)
    @@types[self] ||= {}
    @@types[self][attribute] = type
  end

private
 
  def resolve_types(hash)
    hash.each { |attribute, value|
      case @@types[self.class][attribute]
      when :integer
        hash[attribute] = value.to_i
      when :boolean
        if value == "true"
          hash[attribute] = true
        elsif value == "false"
          hash[attribute] = false
        elsif value != true && value != false
          hash[attribute] = nil
        end
      end
    }
    hash
  end

  def symbolize_keys(hash)
    h = {}
    hash.each { |k, v| h[k.to_sym] = v }
    h
  end

end

