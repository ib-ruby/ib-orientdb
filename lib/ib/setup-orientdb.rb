module HC; end

module IB
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
	# Important: Modules IB, TG and HC have to be initialized before calling connect!
	#
	# A custom directory containing model-files to be included can be provided by setting
	#  -->  ActiveOrient::Model.model_dir 
	#
	def self.connect tws:, orientdb:, kind: :connection
		project_root = File.expand_path('../..', __FILE__)
		ActiveOrient::Init.connect **orientdb
		ActiveOrient::Model.keep_models_without_file = false
		#IB::Model = V   --> Dynamic Assignment Error, this does the same:
		IB.const_set( :Model, V )

  	TG.connect { project_root + '/models'}

		## There are three locations of modelfiles
		## 1. ib-api-model files
		## 2. ib.orientdb-model files
		## 3. lib/modes  (locally)
		model_dir =[ (Pathname.new( `gem which ib-api`.to_s[0..-2]).dirname + "models/").to_s ,
																	 project_root + '/models']
		ActiveOrient::Init.define_namespace { IB  }
		ActiveOrient::OrientDB.new model_dir: model_dir
		ActiveOrient::Init.define_namespace { HC  }
		ActiveOrient::OrientDB.new model_dir: model_dir

		init_database 
		require 'ib/messages'

		target = (kind == :connection) ? IB::Connection : IB::OrientGateway
		if block_given? 
			target.new( **tws )  { |c| yield c  }
		else
			target.new **tws 
		end

		require 'ib/extensions'

	end

	def self.init_database db= V.db
			vertices= db.class_hierarchy( base_class: 'V' ).flatten
			return if vertices.include? "ib_contract"
      init_timegraph
     	ActiveOrient::Init.define_namespace { IB }

			### Vertices
		V.create_class            :contract	, :account  
		IB::Account.create_class  :advisor, :user
		IB::Advisor.create_class  :demo_advisor
		IB::User.create_class     :demo_user
		V.create_class            :portfolio_value, :account_value,  :underlying, 
		                          :contract_detail, :bar, :combo_leg
		IB::Contract.create_class :option, :future, :stock, :forex, :index, :bag
		IB::Bag.create_class      :spread
						
		IB::Contract.create_property :con_id, type: :integer, index: :unique
		IB::Contract.create_property :bars, type: :link_list,  index: :notunique, 																					 linked_class: IB::Bar
		IB::Contract.create_property :contract_detail, type: :link,  index: :notunique, 
		  			      linked_class: IB::ContractDetail
		IB::Account.create_property  :account, type: :string, index: :unique
		IB::Account.create_property  :last_access, type: :date
		IB::User.create_property     :watchlist, type: :map
		IB::PortfolioValue.create_property  :position, type: :decimal
		IB::PortfolioValue.create_property  :market_price, type: :decimal
		IB::PortfolioValue.create_property  :market_value, type: :decimal
		IB::PortfolioValue.create_property  :average_cost, type: :decimal
		IB::PortfolioValue.create_property  :realized_pnl, type: :decimal
		IB::PortfolioValue.create_property  :unrealized_pnl, type: :decimal
		IB::PortfolioValue.create_property  :contract, type: :link, index: :notunique, 
		                                     linked_class: IB::Contract

     	ActiveOrient::Init.define_namespace { HC }
		V.create_class :portfolio 
		HC::Portfolio.create_property :account, type: :link,  index: :notunique, linked_class: IB::Account
		HC::Portfolio.create_property :positions, type: :link_list, linked_class: IB::PortfolioValue
		HC::Portfolio.create_property :values, type:  :map 
			#
			## Edges   (Namespace HC)
		E.create_class :has_portfolio, :has_position,  :grid, :has_account, :has_strategy
		E.create_class  :d2F, :p2U, :my_user
		HC::GRID.uniq_index
		HC::D2F.uniq_index
		HC::MY_USER.uniq_index
	end

	def self.init_timegraph
			## Initialize TimeGraph
		TG::Setup.init_database 
		TG::TimeGraph.populate 1980..2030
		TG.info
	end

	def self.clear_database 
		IB::Account.delete  all: true
                IB::Contract.delete all: true
	end

end
end
