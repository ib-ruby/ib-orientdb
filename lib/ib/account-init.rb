module IB
	module AccountInfos

		def load_managed_accounts

			# defines the callback of the  ManagedAccount message
			#
			# The @accounts-array is initialized with active accounts
		Thread.new do 
			account_class =  ->(a) do
																case a
																when /^U/
																	IB::User
																when /^F/
																	IB::Advisor
																when  /^DF/
																	IB::DemoAdvisor
																when /^DU/
																	IB::DemoUser
																else
																	IB::Account
																end
			end
			@accounts =[]
			c= IB::Connection.current
			man_id = c.subscribe( :ManagedAccounts ) do |msg| 
				@accounts =  msg.accounts_list.split(',').map do |a| 
					account_class[a].new( account: a.upcase ,  last_access: Time.now ).save
				end
			end
			rec_id = c.subscribe( :ReceiveFA )  do |msg|
				msg.accounts.each{ |a| IB::Account.where( account: a.account ).first.update alias: a.alias }
			end

			loop{ sleep 1 ; break if !@accounts.empty? }  # keep it active for 1 second
			c.unsubscribe man_id , rec_id # release callbacks
		end

		end
	end

	#
#2.6.3 :013 > IB::Account.delete  all: true
#03.12.(17:45:47) INFO->delete vertex ib_account 
# => 8 
#2.6.3 :014 > load_managed_accounts
# => #<Thread:0x0000000003d57c78@/home/ubuntu/workspace/ib-orientdb/lib/ib/account_init.rb:9 run> 
#2.6.3 :015 > C.disconnect
# => false 
#2.6.3 :016 > C.connect
#Connected to server, version: 137,
# connection time: 2020-12-03 17:46:03 +0000 local, 2020-12-03T17:46:03+00:00 remote.
#< ManagedAccounts: DF167347 - DU167348 - DU167349>
# => #<Thread:0x0000000003fecee8@/home/ubuntu/workspace/ib-api/lib/ib/connection.rb:379 run> 
#2.6.3 :017 > Got next valid order id: 1.
#TWS Warning 2104: Market data farm connection is OK:eufarm
#
#2.6.3 :018 > IB::Account.all.to_human
#03.12.(17:46:12) INFO->select from ib_account 
# => ["<demo_advisor DF167347>", "<demo_user DU167348>", "<demo_user DU167349>"] 
#
	#

=begin
Queries the tws for Account- and PortfolioValues
The parameter can either be the account_id, the IB::Account-Object or 
an Array of account_id and IB::Account-Objects.

raises an IB::TransmissionError if the account-data are not transmitted in time (1 sec)

raises an IB::Error if less then 100 items are received-
=end
	def get_account_data 

		logger.progname = 'Gateway#get_account_data'


		# Account-infos have to be requested sequentially. 
		# subsequent (parallel) calls kill the former once on the tws-server-side
		# In addition, there is no need to cancel the subscription of an request, as a new
		# one overwrites the active one.
		@accounts.each do | account |
			# don't repeat the query until 170 sec. have passed since the previous update
			if account.lad.nil?  || ( Time.now - account.lad ) > 170 # sec   
				logger.debug{ "#{account.account} :: Requesting AccountData " }
				account[:active] =  false  # indicates: AccountUpdate in Progress, volatile
				# reset account and portfolio-values
				account.portfolio_values =  []
				account.account_values =  []
				send_message :RequestAccountData, subscribe: true, account_code: account.account
				loop{ sleep 0.1; break if account.active  }
#				if watchlists.present?
#					watchlists.each{|w| error "Watchlists must be IB::Symbols--Classes :.#{w.inspect}" unless w.is_a? IB::Symbols }
#					account.organize_portfolio_positions watchlists  
#				end
				send_message :RequestAccountData, subscribe: false  ## do this only once
			else
				logger.info{ "#{account.account} :: Using stored AccountData " }
			end
		end
		nil
	end


  def all_contracts
		clients.map(&:contracts).flat_map(&:itself).uniq(&:con_id)
  end



#	private

	# The subscription method should called only once per session.
	# It places subscribers to AccountValue and PortfolioValue Messages, which should remain
	# active through its session.
	# 
	# Account- and Portfolio-Values are stored in account.account_values and account.portfolio_values
	# The Arrays are volatile.
	
	def subscribe_account_updates continously: true
		puts "SELF: #{self.class.to_s}"
    IB::Connection.current.subscribe( :AccountValue, :PortfolioValue,:AccountDownloadEnd )  do | msg |
			account = @accounts.detect{|a| a.account == msg.account_name }
			case msg
			when IB::Messages::Incoming::AccountValue
				account.account_values = [] unless account.account_values.present?  
				account.account_values.<< msg.account_value

				account[:lad] = Time.now
#				logger.debug { "#{account.account} :: #{msg.account_value.to_human }"}
			when IB::Messages::Incoming::AccountDownloadEnd 
				if account.account_values.size > 10
					# simply don't cancel the subscription if continuously is specified
					# the connected flag is set in any case, indicating that valid data are present
					send_message :RequestAccountData, subscribe: false, account_code: account.account unless continously
					account[:active] = true   ## flag: Account is completely initialized
					logger.info { "#{account.account} => Count of AccountValues: #{account.account_values.size}"  }
				else # unreasonable account_data received -  request is still active
					error  "#{account.account} => Count of AccountValues too small: #{account.account_values.size}" , :reader 
				end
			when IB::Messages::Incoming::PortfolioValue
				account.contracts << msg.contract.save
				account.portfolio_values << msg.portfolio_value 
				logger.debug { "#{ account.account } :: #{ msg.contract.to_human }" }
			end # case
		end # subscribe
	end  # def 



end
