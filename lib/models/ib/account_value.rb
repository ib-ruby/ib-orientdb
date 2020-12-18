module IB
	class AccountValue 
		
		# Assigns an AccountValue to the TimeGrid and inserts a link to the account to the  AccountValueRecord
		def bake account:, date:  Date.today, via: IB::HAS_ACCOUNT
			self.attributes[:account]= account.rid
			date.to_tg.assign vertex = self, via: via
		end



		def self.bake from:, with:

		user = HC::Users.where( account_id: with.is_a?(String) ? with : with.account ) &.first

		raise ArgumentError "No HC::Users record available" unless user.is_a? HC::Users
		
		time_graph_index =  Date.today.to_tg
#		from.each do | account_value |
			new_ds = create values: {},  account: user, date: Date.today
			new_ds.values << from
			HC::AV.create from: time_graph_index, to: new_ds
			HC::MY_USER.create from:  user, to: new_ds


		end

	end
end
