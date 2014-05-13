module Perm
  class Role
    def initialize(name)
      @name = name
    end
    attr_reader :name

    def self.[] role_name
      Perm.schema.roles_by_name[role_name]
    end

    def can?(right_name)
      rights.include? right_name
    end

    def rights
      @rights ||= []
    end

    def grant_rights(rights)
      self.rights.concat rights
    end

    def revoke_rights(rights)
      @rights -= rights
    end
  end
end
