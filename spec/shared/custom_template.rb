# encoding: utf-8

# Creates file `/config/custom_migration.txt` for a custom template.
shared_context :custom_template do
  let(:template) { "/config/custom_migration.txt" }

  before do
    # create folder
    FileUtils.mkdir_p "/config"

    File.new(template, "w").write <<-TEXT.gsub(/ *\|/, "")
      |ROM::Migrator.migration do
      |  up do
      |  end
      |
      |  down do
      |  end
      |end
    TEXT
  end
end
