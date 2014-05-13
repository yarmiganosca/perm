require "perm/role"
require 'singleton'

module Perm
  def self.schema
    Schema.instance
  end

  class Schema
    include Singleton

    def create_role(role_name, &blk)
      Role.new(role_name, &blk).tap do |role|
        roles_by_name[role.name] = role
      end
    end

    def delete_role(role_name)
      roles_by_name.delete(role_name)
    end

    def roles_by_name
      @roles_by_name ||= {}
    end

    def grant_rights(role_name, right_names)
      roles_by_name[role_name].grant_rights(right_names)
    end

    def revoke_rights(role_name, right_names)
      roles_by_name[role_name].revoke_rights(right_names)
    end
  end
end
