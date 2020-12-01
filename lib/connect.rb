module Setup
	# connects to a running interactive brokers TWS or Gateway
	# and to an active OrientDB-Server.
	#
	#
	# Parameter tws:   host: (default 'localhost') 
	#                  port: (default 4002 , specify 4001/4002 (Gateway) or 7496/7497 ())
	# Parameter orientdb: server: ( default: 'localhost' )
	#                     user: 
	#                     password:
	#                     database: ( default: 'temp' )
	#
	# The parameter are transmitted to IB::Connection and OrientDB without further checking
	#
	# It returns the active Connection 
	#
	# The optional block is evaluated in the context of the initialized, but not connected IB::Connection.
	#
	#
	def self.connect tws:, orientdb:
		ActiveOrient::Init.connect **orientdb
		ActiveOrient::Init.define_namespace { IB  }
		#IB::Model = V   --> Dynamic Assignment Error, this does the same:
		IB.const_set(:Model, V )

		## There are two locations of modelfiles
		## 1. ib-api-model files
		## 2. ib.orientdb-model files
		project_root = File.expand_path('../..', __FILE__)
		puts "PR: " , project_root
		ActiveOrient::Model.model_dir =[ (Pathname.new( `gem which ib-api`.to_s[0..-2]).dirname + "models/").to_s ,
																	 project_root + '/lib/models']

		ActiveOrient::OrientDB.new  


		Setup.init_database 
		
		require 'ib/messages'
		# include extensions after initializing the database and final database-class assignments
		# 
		# otherwise superclass missmatches can pop up. 

		if block_given? 
			IB::Connection.new( **tws )  { |c| yield c  }
		else
			IB::Connection.new **tws 
		end


		require 'ib/extensions'

	end
end
