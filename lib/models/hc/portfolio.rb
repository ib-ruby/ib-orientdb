module HC
	class Portfolio 
		# describes the snapshot of positions and account-values
		# is stored on a daily base
		#
		#
		# bake generates portfolio-entries for each detected IB::Account,
		#  stores converted account-values in the portfolio-record,
		#  assigns Portfolio-positions to the time-grid and
		#  connects the record to the referenced IB::Account.
		#
		# returns an array with rid's of successfully allocated portfolio-datasets 
		#
    def self.bake  

			gateway= IB::OrientGateway.current
      gateway.get_account_data
			gateway.clients.map do | the_client |

				p = self.new
				p.import_account_data from: the_client						 # implies update of p, assigns a rid
				p.import_positions    from: the_client             # assigns portfolio-values to the grid
				HC::MY_USER.create    from: p, to: the_client      # bidirectional link to account
				Date.today.to_tg.assign vertex: p, via: HC::D2F    # bidirectional link to the time-grid
				p.rid                                              # return_value
			end
		end

		# returns  the projection for usage in OrientQuery
		# It filters specific account-values
		#
		# To execute a query, inject the from-parameter via a block
		#
		def account_data_scan_projection search_key
			# values.keys.match(/Ac/).compact.string => ["AccruedCash", "AccruedDividend"]
			fields = values.keys.match(search_key).compact.string 
      p = fields.map{|y| "values[\"#{y}\"] as #{y} "}.join(", ")
      if block_given?
				 q =  OrientSupport::OrientQuery  
				 o.from( yield )
				  .projection( p )
					.execute     # return result
         else
					 p  #  return projection string
			end


		end

# pp Date.today.to_tg.environment(3,0) &.out_hc_d2F.compact.in.values.orient_flatten.map{|y| y[:SMA] }
#[{:ALL=>{:EUR=>-4701.63}, :S=>{:EUR=>-4701.63}},
# {:ALL=>{:EUR=>-4702.72}, :S=>{:EUR=>-4702.72}},
# {:ALL=>{:EUR=>-4658.85}, :S=>{:EUR=>-4658.85}},
# {:ALL=>{:EUR=>-4658.85}, :S=>{:EUR=>-4658.85}},
# {:ALL=>{:EUR=>-4658.85}, :S=>{:EUR=>-4658.85}},
# {:ALL=>{:EUR=>-5840.75}, :S=>{:EUR=>-5840.75}},
# {:ALL=>{:EUR=>-9033.37}, :S=>{:EUR=>-9033.37}}]
# 


		def account_data_scan search_key, search_currency=nil
			return if values.nil? or values.empty?
		   values.keys.match(/Ac/).compact.string
			if account_values.is_a? Array
				if search_currency.present? 
					account_values.find_all{|x| x.key.match( search_key )  && x.currency == search_currency.upcase }
				else
					account_values.find_all{|x| x.key.match( search_key ) }
				end
			end
		end

		# Utility function to transform IB:AccountValues into a hash 
		#
		# which is stored in the property »value«
		#
		# from is either a IB::Account or an array of IB::AccountValues
		def import_account_data  from:
			from = from.account_values if from.is_a? IB::Account
			account_values =  Hash.new
			currencies = from.find_all{|x| x.key == :Currency }.map &:value  # => ["BASE", "EUR", "SEK", "USD"]
			from.map{|y| y.key.to_s.split('-').first.to_sym}.uniq.each{|x| account_values[ x ] = {} }
			subaccounts = [:C, :F, :S]
			
			from.each do |a|
				next if a.currency.empty? || a.value.to_i.zero? || a.value == "1.7976931348623157E308"
				id, subaccount =  a.key.to_s.split('-')
#				a.value =  a.value[-3] =='.' ?  a.value.to_f : a.value.to_i  if a.value.is_a?(String)
				a.value =  a.value.to_f
				subaccount = 'ALL' if subaccount.nil? 
				if account_values[id.to_sym][subaccount.to_sym].present? 
					account_values[id.to_sym][subaccount.to_sym].merge!  a.currency => a.value  
				else
					account_values[id.to_sym][subaccount.to_sym] = { a.currency => a.value } 
				end
			end
			account_values.delete_if{|_,l| l.empty?}  # return only elements with valid data, ie.non empty values

			update  values: account_values
		end
		
	
		# Utility function to add IB::PortfolioValues to the TimeGrid
		#
		# from is either a IB::Account or an array of IB::PortfolioValues
		#
		def import_positions from: 
			from = from.portfolio_values if from.is_a? IB::Account

			# delete possibly previous entries
			out_hc_has_position &.in &.map &:delete
#			out_hc_has_position &.map &:delete			#  edge is automatically removed by delete(vertex)

			from.each do | portfolio_position |

				portfolio_position.save
				# build link to portfolio-position
				assign via: HC::HAS_POSITION, vertex: portfolio_position
				# connect with previous entry
				previous = prev_portfolio_position(portfolio_position.contract)
#				puts "previous: #{previous}"
				previous &.assign via: HC::GRID, vertex: pp
			end
		end

	# go back one step in history, traverse to the portfolio_position where the contract matches
		def prev_portfolio_position(contract)
				prev &.position( contract )
		end

		# shortcut for the portfolio-positions-array
		def positions
			out( HC::HAS_POSITION ).in  #  ruby solution, without inheritance
		end
			 #################
##			 nodes :out, via: HC::HAS_POSITION   # database-query solution with inheritance
			 #################

		def self.positions
				query.nodes :out, via: HC::HAS_POSITION, expand: false  # returns a query-object
		end

		# get selected portfolio-value positions
		def position *contract 
      
			# generated query: INFO->select  outE('hc_has_position').in[ contract=208:0 ]  from #249:0 
		  nodes :out, via: HC::HAS_POSITION , where: { contract: contract }  # database-query solution
			#positions &.detect{|x| x.contract == contract }   # ruby solution
		end
	
		def account
			out( /user/ ).in.first
		end


		def to_human
					"<#{self.class.to_s.split(':').last}[#{rid}]: account:#{account.to_human}, #{values.size} AccountValues; #{out_hc_has_position.size} Positions >"
		end

	end # class
end   # module
