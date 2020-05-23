module DBConnection
	def self.connect
	  $conn = PG.connect(ENV.fetch("DATABASE_URL", { dbname: "felix" }))
	end
end