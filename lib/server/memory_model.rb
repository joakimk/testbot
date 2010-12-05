class MemoryModel < OpenStruct

  @@db = {}
  attr_reader :id, :type

  def initialize(hash)
    h = {}
    hash.each { |k, v| h[k.to_sym] = v }
    @id = h[:id]
    @type = h[:type]
    super(h)
  end

  def delete
    self.class.all.delete_if { |b| b.id == id }
  end

  def destroy
    delete
  end

  def update(hash)
    @table.merge!(hash)
  end

  def reload
    self
  end

  def self.find(id)
    all.find { |r| r.id == id }
  end

  def self.create(hash = {})
    all << new(hash.merge({ :id => all.size }))
    all[-1]
  end

  def self.all
    @@db[self] ||= []
    @@db[self]
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

end

