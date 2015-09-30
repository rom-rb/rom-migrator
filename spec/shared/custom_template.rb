# encoding: utf-8

# Creates file `/config/custom_migration.erb` for a custom template.
shared_context :custom_template do
  let(:template) { "/config/custom_migration.erb" }

  before do
    # create folder
    FileUtils.mkdir_p "/config"

    File.new(template, "w").write <<-TEXT.gsub(/ *\|/, "")
      |class <%= @klass %> < ROM::Migrator::Migration
      |  def up; end
      |  def down; end
      |end
    TEXT
  end
end
