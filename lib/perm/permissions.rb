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
      rights_by_name.has_key?(right_name)
    end

    def rights_by_name
      @rights_by_name ||= {}
    end

    def grant_rights(right_names)
      right_names.each do |right_name|
        rights_by_name[right_name] = Right.new(right_name)
      end
    end

    def revoke_rights(right_names)
      right_names.each do |right_name|
        rights_by_name.delete(right_name)
      end
    end
  end
end

module Perm
  class Right
    def initialize(name)
      @name = name
    end
    attr_reader :name
  end
end

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

describe Perm::Migration do
  let(:create_user_and_admin) do
    Perm::Migration.new(:create_user_and_admin) do
      create_role :user
      create_role :admin
    end
  end

  describe "#name" do
    let(:migration) { create_user_and_admin }

    it "returns the name of the migration" do
      migration.name.must_equal :create_user_and_admin
    end
  end

  describe "#create_role" do
    let(:migration) { create_user_and_admin }

    describe "applying" do
      before { migration.apply! }
      after { migration.reverse! }

      it "applies the changes in the migration" do
        [:user, :admin].each do |role_name|
          Perm::Role[role_name].name.must_equal role_name
        end
      end

      it "is idempotent" do
        migration.apply!

        Perm.schema.roles_by_name.size.must_equal 2
      end
    end

    describe "reversing" do
      before { migration.apply! }

      it "undoes the migration" do
        migration.reverse!

        [:user, :admin].each do |role_name|
          Perm::Role[role_name].must_be_nil
        end
      end
    end
  end

  let(:grant_user_and_admin_rights) do
    Perm::Migration.new(:grant_user_and_admin_rights) do
      role(:user).can :use
      role(:admin).can :use, :administrate
    end
  end

  describe "#role" do
    let(:migrations) { [create_user_and_admin, grant_user_and_admin_rights] }

    describe "granting" do
      before { migrations.each(&:apply!) }
      after { migrations.reverse.each { |m| m.reverse! } }

      it "creates the necessary rights" do
        Perm::Role[:user].can?(:use).must_equal true
        Perm::Role[:user].can?(:administrate).must_equal false

        Perm::Role[:admin].can?(:use).must_equal true
        Perm::Role[:admin].can?(:administrate).must_equal true
      end
    end
  end
end
