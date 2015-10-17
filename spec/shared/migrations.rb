# encoding: utf-8

# Creates 3 files for migrations:
#
# * `/db/migrate/1_create_users.rb
# * `/db/migrate/3_create_accounts.rb
# * `/spec/dummy/db/migrate/2_create_roles.rb
#
shared_context :migrations do
  let(:paths) { %w(/db/migrate /spec/dummy/db/migrate) }

  before do
    paths.each(&FileUtils.method(:mkdir_p))

    File
      .new("db/migrate/1_create_users.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |ROM::Migrator.migration do
        |  up { go "CREATE TABLE users;" }
        |  down { go "DROP TABLE users;" }
        |end
      TEXT

    File
      .new("spec/dummy/db/migrate/2_create_roles.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |ROM::Migrator.migration {
        |  up do
        |    go "CREATE TABLE roles;"
        |  end
        |
        |  down do
        |    go "DROP TABLE roles;"
        |  end
        |}
      TEXT

    File
      .new("db/migrate/3_create_accounts.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |ROM::Migrator.migration do
        |  up do
        |    go "CREATE TABLE accounts;"
        |  end
        |
        |  down do
        |    go "DROP TABLE accounts;"
        |  end
        |end
      TEXT

    File
      .new("db/migrate/_unnumbered.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |ROM::Migrator.migration do
        |  up do
        |    go "CREATE TABLE ghosts;"
        |  end
        |
        |  down do
        |    go "DROP TABLE ghosts;"
        |  end
        |end
      TEXT

    File
      .new("db/migrate/4_not_a_migration.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |up do
        |  go "CREATE TABLE things;"
        |end
        |
        |down do
        |  go "DROP TABLE things;"
        |end
      TEXT

    File
      .new("db/migrate/5_symbol.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |:foo
      TEXT

    File
      .new("db/migrate/6_symbol_class.rb", "w")
      .write <<-TEXT.gsub(/ *\|/, "")
        |Symbol
      TEXT
  end
end
