module IB
	class PortfolioValue

		def save
			super
			contract.save unless contract.rid.rid?
			update contract: contract.rid
		end
	end
end
