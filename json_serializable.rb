require "json"

module JSONSerializable

  def as_json(options={})
    {}.tap do |data|
      self.instance_variables.lazy.each do |iv|
        data[iv.to_s.gsub("@", '')] = self.instance_variable_get(iv) if self.valid?
      end
    end
  end

  def to_json(*options)
    as_json(*options).to_json(*options)
  end

end
