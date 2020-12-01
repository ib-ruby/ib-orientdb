#require 'bunny'
require 'active_support'
require 'active-orient'
require 'orientdb_time_graph'
require 'ib-api'
require 'dry/core/class_attributes'
require_relative "logging"
require_relative "db_init"
	

module HC 

	def setup environment = :test, port = 4002 
 #   mattr_accessor :orient 
	 ActiveOrient::Init.connect  database: (environment == :production) ?  'hc' : 'hc-test',
				user: 'hctw',
				password: 'hc',
				server: '172.28.50.25'

#    mattr_accessor :tws
	 unless port.to_i.zero?
		 begin	
			 IB::Gateway.new  get_account_data: false, serial_array: false,
				 subscribe_managed_accounts: false, 
				 subscribe_alerts: true, 
				 subscribe_order_messages: false,
				 client_id: (environment == :production) ? 4443 : 4444  ,# port: port, 
				 host: (environment == :production) ? '10.222.148.177:7496' :'localhost:4002',
				 logger: ActiveOrient::Base.logger,
			 watchlists: [:Spreads, :BuyAndHold, :Trend, :HC, :Stillhalter, :Hedge, :Bond]

		 rescue IB::TransmissionError => e
			 puts "E: #{e.inspect}"
		 end
		 require_relative 'gateway_ext'
	 end


	  
	
		ActiveOrient::Init.define_namespace { TG } 
		TG.connect
		# we have to initialise the timegraph at this point, otherwise any
		# manual requirement fails.
		unless ActiveOrient::Model.namespace.send :const_defined?, 'Tag' 
			Setup.init_database V.orientdb
		end
#		module ML; end
		project_root = File.expand_path('../..', __FILE__)
		ActiveOrient::Model.model_dir =  project_root + '/model'
		ActiveOrient::Init.define_namespace { HC }
		ActiveOrient::Model.keep_models_without_file = true
		ActiveOrient::OrientDB.new  preallocate: true 
	
		require ActiveOrient::Model.model_dir+"/tg/tag.rb"
#		require ActiveOrient::Model.model_dir+"/tg/monat.rb"
	end
 end
