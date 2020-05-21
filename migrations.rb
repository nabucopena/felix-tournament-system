require "pg"
conn = if ENV["DATABASE_URL"]
         PG.connect(ENV["DATABASE_URL"])
       else
         PG.connect(dbname: "felix")
       end
def getnumber(str)
	str.split("_").first.to_i
end

conn.exec("create table if not exists migrations
	(file text not null)")
migrations = Dir.children("migrations")
executed_migrations = conn.exec("select file from migrations").
	to_a.
	map { |item| item.fetch("file")}
migrations_to_run = migrations-executed_migrations
migrations_to_run.sort_by{ |item| getnumber(item)}.each do |filename|
	conn.exec(File.read("#{__dir__}/migrations/#{filename}"))
	conn.exec_params("insert into migrations(name) values($1)", filename)
end
