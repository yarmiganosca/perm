require "perm/alteration"

module Perm
  class Migration
    def initialize(name, &blk)
      @name        = name
      @alterations = []
      instance_eval &blk
    end
    attr_reader :name, :alterations

    def apply!
      alterations.each(&:apply!)
    end

    def reverse!
      alterations.reverse.each do |alteration|
        alteration.reverse.apply!
      end
    end

    def create_role(role_name)
      RoleCreation.new(self, role_name).tap { |_| alterations << _ }
    end

    def grant_rights(role_name, right_names)
      alterations << GrantCreation.new(self, role_name, right_names)
    end

    def role(role_name)
      GrantAlterationProxy.new(self, role_name)
    end

    class GrantAlterationProxy
      def initialize(migration, role_name)
        @migration = migration
        @role_name = role_name
      end
      attr_reader :migration, :role_name

      def can(*right_names)
        migration.grant_rights(role_name, right_names)
      end
    end
  end
end
