require "pg"
conn = PG.connect(ENV.fetch("DATABASE_URL", { dbname: "felix" }))

conn.exec("create table if not exists migrations
	(file text not null)")
migrations = Dir.children("migrations")
executed_migrations = conn.exec("select file from migrations").
	to_a.
	map { |item| item.fetch("file")}
migrations_to_run = migrations - executed_migrations
migrations_to_run.sort_by(&:to_i).each do |filename|
	conn.exec(File.read("#{__dir__}/migrations/#{filename}"))
	conn.exec_params("insert into migrations(file) values($1)", [filename])
end
