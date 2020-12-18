#
require_relative 'account-init'
#require 'ib/gateway/order-handling'
require_relative '../alerts/base-alert'
require_relative '../alerts/gateway-alerts'
require_relative '../alerts/order-alerts'
require 'active_support/core_ext/module/attribute_accessors'   # provides m_accessor
#module GWSupport
# provide  AR4- ActiveRelation-like-methods to Array-Class

module IB

=begin
The  Gateway-Class defines anything which has to be done before a connection can be established.
The Default Skeleton can easily be substituted by customized actions

The IB::Gateway can be used in three modes
(1) IB::Gateway.new( connect:true, --other arguments-- ) do | gateway |
	** subscribe to Messages and define the response  **
	# This block is executed before a connect-attempt is made 
		end
(2) gw = IB:Gateway.new
		** subscribe to Messages **
		gw.connect
(3) IB::Gateway.new connect:true, host: 'localhost' ....

Independently IB::Alert.alert_#{nnn} should be defined for a proper response to warnings, error-
and system-messages. 


The Connection to the TWS is realized throught IB::Connection. Additional to __IB::Connection.current__
IB::Gateway.tws points to the active Connection.

To support asynchronic access, the :recieved-Array of the Connection-Class is not active.
The Array is easily confused, if used in production mode with a FA-Account and has limits.
Thus IB::Conncetion.wait_for(message) is not available until the programm is called with
IB::Gateway.new  serial_array: true (, ...)



=end

	class OrientGateway

		include LogDev   # provides default_logger
		include IB::AccountInfos
	#	include IB::AccountInfos  # provides Handling of Account-Data provided by the tws
#		include OrderHandling 

		# include GWSupport   # introduces update_or_create, first_or_create and intercept to the Array-Class

		# from active-support. Add Logging at Class + Instance-Level
		mattr_accessor :logger
		# similar to the Connection-Class: current represents the active instance of Gateway
		mattr_accessor :current
		mattr_accessor :tws



		def initialize  port: 4002, # 7497, 
			host: '127.0.0.1',   # 'localhost:4001' is also accepted
			client_id:  random_id,
			subscribe_managed_accounts: true, 
			subscribe_alerts: true, 
			subscribe_order_messages: true, 
			connect: true, 
			get_account_data: false,
			serial_array: false, 
			logger: default_logger,
			watchlists: [] ,  # array of watchlists (IB::Symbols::{watchlist}) containing descriptions for complex positions
			**other_agruments_which_are_ignored,
			&b

			host, port = (host+':'+port.to_s).split(':') 

			self.logger = logger
			logger.info { '-' * 20 +' initialize ' + '-' * 20 }
			logger.tap{|l| l.progname =  'Gateway#Initialize' }

			@connection_parameter = { received: serial_array, port: port, host: host, connect: false, logger: logger, client_id: client_id }

			@accounts = []
			@watchlists = watchlists
			@gateway_parameter = { s_m_a: subscribe_managed_accounts, 
													s_a: subscribe_alerts,
													s_o_m: subscribe_order_messages,
													g_a_d: get_account_data }


			Thread.report_on_exception = true
			# https://blog.bigbinary.com/2018/04/18/ruby-2-5-enables-thread-report_on_exception-by-default.html
			self.current = self
			# establish Alert-framework
			#IB::Alert.logger = logger
			# initialise Connection without connecting
			prepare_connection &b
			# finally connect to the tws
			connect =  true if get_account_data
			if connect 
				if connect(100)  # tries to connect for about 2h
					get_account_data()  if get_account_data
					#    request_open_orders() if request_open_orders || get_account_data 
				else
					@accounts = []   # definitivley reset @accounts
				end
			end

		end

		def active_watchlists
			@watchlists
		end

		def get_host
			"#{@connection_parameter[:host]}: #{@connection_parameter[:port] }"
		end

		def update_local_order order
			# @local_orders is initialized by #PrepareConnection
			@local_orders.update_or_create order, :local_id
		end


		## ------------------------------------- connect ---------------------------------------------##
=begin
Zentrale Methode 
Es wird ein Connection-Objekt (IB::Connection.current) angelegt.
Sollte keine TWS vorhanden sein, wird eine entsprechende Meldung ausgegeben und der Verbindungsversuch 
wiederholt.
Weiterhin meldet sich die Anwendung zur Auswertung von Messages der TWS an.

=end
		def connect maximal_count_of_retry=100

			i= -1
			logger.progname =  'Gateway#connect' 
			begin
				tws.connect
			rescue  Errno::ECONNREFUSED => e
				i+=1
				if i < maximal_count_of_retry
					if i.zero?
						logger.info 'No TWS!'
					else
						logger.info {"No TWS        Retry #{i}/ #{maximal_count_of_retry} " }
					end
					sleep i<50 ? 10 : 60   # Die ersten 50 Versuche im 10 Sekunden Abstand, danach 1 Min.
					retry
				else
					logger.info { "Giving up!!" }
					return false
				end
			rescue Errno::EHOSTUNREACH => e
				logger.error 'Cannot connect to specified host'
				logger.error  e
				return false
			rescue SocketError => e
				logger.error 'Wrong Adress, connection not possible'
				return false
			end

			tws.start_reader
			# let NextValidId-Event appear
			(1..30).each do |r|
				break if tws.next_local_id.present?
				sleep 0.1
				if r == 30
					error "Connected, NextLocalId is not initialized. Repeat with another client_id"
				end
			end
			# initialize @accounts (incl. aliases)
			tws.send_message :RequestFA, fa_data_type: 3
			logger.debug { "Communications successfully established" }
		end	# def





		def reconnect
			logger.progname = 'Gateway#reconnect'
			if tws.present?
				disconnect
				sleep 1
			end
			logger.info "trying to reconnect ..."
			connect
		end

		def disconnect
			logger.progname = 'Gateway#disconnect'

			tws.disconnect if tws.present?
			@accounts = [] # each{|y| y.update_attribute :connected,  false }
			logger.info "Connection closed" 
		end


=begin
Proxy for Connection#SendMessage
allows reconnection if a socket_error occurs

checks the connection before sending a message.

=end

		def send_message what, *args
			logger.tap{|l| l.progname =  'Gateway#SendMessage' }
			begin
				if	check_connection
					tws.send_message what, *args
				else
					error( "Connection lost. Could not send message  #{what}" )
				end
			end
		end

=begin
Cancels one or multible orders

Argument is either an order-object or a local_id

=end

		def cancel_order *orders 

			logger.tap{|l| l.progname =  'Gateway#CancelOrder' }

			orders.compact.each do |o|
				local_id = if o.is_a? (IB::Order)
										 logger.info{ "Cancelling #{o.to_human}" }
										 o.local_id
									 else
										 o
									 end
				send_message :CancelOrder, :local_id => local_id.to_i
			end

		end

=begin
clients returns a list of Account-Objects 

If only one Account is present,  Client and Advisor are identical.

=end
		def  clients
			@accounts.find_all{ |x| x.is_a? IB::User }   # IB::User and IB::DemoUser 
		end
=begin
The Advisor is always the first account. Anything works with single user accounts as well.
=end
		def advisor
			@accounts.first
		end

=begin
account_data provides a thread-safe access to linked content of accounts

(AccountValues, Portfolio-Values, Contracts and Orders)

It returns an Array of the return-values of the block

If called without a parameter, all clients are accessed
=end

		def account_data account_or_id=nil

			safe = ->(account) do
				@account_lock.synchronize do
					yield account 
				end
			end

			if block_given?
				if account_or_id.present?
					sa = account_or_id.is_a?(IB::Account) ? account_or_id :  @accounts.detect{|x| x.account == account_or_id }
					safe[sa] if sa.is_a? IB::Account
				else
					clients.map{|sa| safe[sa]}
				end
			end
		end


		private

		def random_id
			rand 99999
		end


		def prepare_connection &b
			self.tws = IB::Connection.new  @connection_parameter, &b
			@accounts = @local_orders = Array.new
			load_managed_accounts if @gateway_parameter[:s_m_a]
			# prepare Advisor-User hierachy
			initialize_alerts if @gateway_parameter[:s_a]
		#	initialize_order_handling if @gateway_parameter[:s_o_m] || @gateway_parameter[:g_a_d] 
			subscribe_account_updates  #   account-init.rb
			 
			 ## apply other initialisations which should apper before the connection as block
			## i.e. after connection order-state events are fired if an open-order is pending
			## a possible response is best defined before the connect-attempt is done
			# ##  Attention
			# ##  @accounts are not initialized yet (empty array)
#			if block_given? 
#				yield  self

#			end
		end


		def initialize_alerts

			tws.subscribe(  :AccountUpdateTime  ){| msg | logger.debug{ msg.to_human }}
			tws.subscribe(:Alert) do |msg| 
				logger.progname = 'Gateway#Alerts'
				logger.debug " ----------------#{msg.code}-----"
				# delegate anything to IB::Alert
				IB::Alert.send("alert_#{msg.code}", msg )
			end
		end


		# Handy method to ensure that a connection is established and active.
		#
		# The connection is reset on the IB-side at least once a day. Then the 
		# IB-Ruby-Connection has to be reestablished, too. 
		# 
		# check_connection reconnects if necessary and returns false if the connection is lost. 
		# 
		# It delays the process by 6 ms (150 MBit Cable connection)
		#
		#  a =  Time.now; G.check_connection; b= Time.now ;b-a
		#   => 0.00066005
		# 
		def check_connection
			answer = nil; count=0
			z= tws.subscribe( :CurrentTime ) { answer = true }
			while (answer.nil?)
				begin
					tws.send_message(:RequestCurrentTime)												# 10 ms  ##
					i=0; loop{ break if answer || i > 40; i+=1; sleep 0.0001}
				rescue IOError, Errno::ECONNREFUSED   # connection lost
					count = 6
				rescue IB::Error # not connected
					reconnect 
					count +=1
					sleep 1
					retry if count <= 5
				end
				count +=1
				break if count > 5
			end
			tws.unsubscribe z
			count < 5  && answer #  return value
		end
	end  # class

end # module

