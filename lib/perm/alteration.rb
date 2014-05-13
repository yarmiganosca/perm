module Perm
  class Migration
    class Alteration
      def initialize(migration, *args)
        @migration = migration

        msg, args = self.class.apply_message, args

        @applier = Proc.new do |schema|
          schema.send msg, *args
        end

        @reverser = Proc.new do
          self.class.reverse_factory.call.new(migration, *args)
        end
      end
      attr_reader :migration, :applier, :reverser

      def apply!
        applier.call(Perm.schema)
      end

      def self.applies msg
        @apply_message ||= msg
      end

      def reverse
        reverser.call
      end

      def self.reverse_of &blk
        @reverse_factory ||= blk
      end

      private

      def self.apply_message
        @apply_message
      end

      def self.reverse_factory
        @reverse_factory
      end
    end

    class RoleCreation < Alteration
      reverse_of { RoleDeletion }
      applies :create_role
    end

    class RoleDeletion < Alteration
      reverse_of { RoleCreation }
      applies :delete_role
    end

    class GrantCreation < Alteration
      reverse_of { GrantDeletion }
      applies :grant_rights
    end

    class GrantDeletion < Alteration
      reverse_of { GrantCreation }
      applies :revoke_rights
    end
  end
end
