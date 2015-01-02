namespace :db do
  desc "Migrates the database to the latest available version\n\nRequires that OMOIKANE_DATABASE_URL be correctly set to function."
  task :migrate do
    sh "sequel --echo --migrate-directory db/migrate #{ENV.fetch("OMOIKANE_DATABASE_URL")}"
  end
end
