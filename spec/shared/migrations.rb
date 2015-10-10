# encoding: utf-8

# Creates 3 files for migrations:
#
# * `/db/migrate/1_create_users.rb
# * `/db/migrate/3_create_accounts.rb
# * `/spec/dummy/db/migrate/2_create_roles.rb
#
shared_context :migrations do
  let(:folders) { %w(/db/migrate /spec/dummy/db/migrate) }

  before do
    folders.each(&FileUtils.method(:mkdir_p))

    File
      .new("db/migrate/1_create_users.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |class CreateUsers < ROM::Migrator::Migration
        |  up do
        |    go "CREATE TABLE users;"
        |  end
        |
        |  down do
        |    go "DROP TABLE users;"
        |  end
        |end
      TEXT

    File
      .new("spec/dummy/db/migrate/2_create_roles.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |class CreateRoles < ROM::Migrator::Migration
        |  up do
        |    go "CREATE TABLE roles;"
        |  end
        |
        |  down do
        |    go "DROP TABLE roles;"
        |  end
        |end
      TEXT

    File
      .new("db/migrate/3_create_accounts.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |class CreateAccounts < ROM::Migrator::Migration
        |  up do
        |    go "CREATE TABLE accounts;"
        |  end
        |
        |  down do
        |    go "DROP TABLE accounts;"
        |  end
        |end
      TEXT
  end
end
