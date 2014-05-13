require_relative 'spec_helper'

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
