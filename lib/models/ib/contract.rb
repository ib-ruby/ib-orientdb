module IB
	class Contract  < IB::Model

		# if con_id is not set, the contract cannot be saved
		#
		# if con_id or rid is present, the contract is updated
		def save
			return false if con_id.blank? || con_id.zero?
			super
		end
	end

end


