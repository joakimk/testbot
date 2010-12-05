class MemoryModel < OpenStruct

  @@db = {}
  @@next_id = 1
  attr_reader :id, :type

  def initialize(hash)
    hash = symbolize_keys(hash)
    @id = hash[:id]
    @type = hash[:type]
    super(hash)
  end


  def delete
    self.class.all.delete_if { |b| b.id == id }
  end

  def destroy
    delete
  end

  def update(hash)
    @table.merge!(symbolize_keys(hash))
    self
  end

  def reload
    self
  end

  def self.find(id)
    all.find { |r| r.id == id }
  end

  def self.create(hash = {})
    all << new(hash.merge({ :id => @@next_id }))
    @@next_id += 1
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

  def [](attr)
    send(attr)
  end

  def self.count
    all.size
  end

private

  def symbolize_keys(hash)
    h = {}
    hash.each { |k, v| h[k.to_sym] = v }
    h
  end

end

