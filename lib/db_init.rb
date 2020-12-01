module  Setup
	def self.init_database db= V.db
			#vertices =  db.class_hierarchy["V"].flatten
			vertices= db.class_hierarchy( base_class: 'V' ).flatten
			return if vertices.include? "ib_contract"
     	ActiveOrient::Init.define_namespace { IB }

			### Vertices
		  V.create_class :contract	, :account  
			IB::Account.create_class :advisor, :user
			IB::Advisor.create_class :demo_advisor
			IB::User.create_class :demo_user
			V.create_class :portfolio, :portfolio_value, :account_value,  :underlying, :contract_detail, :bar
			IB::Contract.create_class :option, :future, :stock, :forex, :index, :bag
			IB::Bag.create_class :spread
#			IB::Accounts.create_property( :account_id, type: :string, index: :unique)
	
						
		  IB::Contract.create_property :con_id, type: :integer, index: :unique
		  IB::Contract.create_property :bars, type: :link_list,  index: :notunique, 
																										 linked_class: IB::Bar
		  IB::Contract.create_property :contract_detail, type: :link,  index: :notunique, 
																										 linked_class: IB::ContractDetail
			IB::Portfolio.create_property :account, type: :link,  index: :notunique, linked_class: IB::Account
			IB::Portfolio.create_property :positions, type: :link_list, linked_class: IB::PortfolioValue

			IB::Account.create_property  :last_access, type: :date
			IB::Account.create_property  :account, type: :string, index: :unique
			IB::User.create_property :watchlist, type: :map
			IB::PortfolioValue.create_property  :position, type: :decimal
			IB::PortfolioValue.create_property  :market_price, type: :decimal
			IB::PortfolioValue.create_property  :market_value, type: :decimal
			IB::PortfolioValue.create_property  :average_cost, type: :decimal
			IB::PortfolioValue.create_property  :realized_pnl, type: :decimal
			IB::PortfolioValue.create_property  :unrealized_pnl, type: :decimal
		  IB::PortfolioValue.create_property :contract, type: :link, index: :notunique, linked_class: IB::Contract


			## Edges 
			E.create_class :has_portfolio, :has_position,  :grid, :has_account, :has_strategy
			IB::GRID.uniq_index

			## Initialize TimeGraph
	#		TG::Setup.init_database 
	#		TG::TimeGraph.populate 1980..2030
	#		TG.info
			
	end

	def self.clear_database 
#		IB::Account.delete  all: true
    IB::Contract.delete all: true

	end
end
