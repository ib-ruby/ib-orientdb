require 'spec_helper'
require 'database_helper'


RSpec.describe 'IB::Contract' do
	before(:all) do
		 connect   #  database is empty
		 Setup.clear_database
end

	context "allocate a stock" do
		before(:all){ @ge =  IB::Stock.new symbol: 'GE' }

		it "is not allocated to the database" do
			expect( @ge.rid.rid?  ).to be_nil
		end

		it "can not be saved to the database" do
			@ge.save
			expect( @ge.rid.rid?  ).to be_nil
			expect( IB::Stock.count ).to be_zero
		end


		it "can be verified and then stored in the database" do
			verified_ge =  @ge.verify
			expect( verified_ge ).to be_an Array
			expect( verified_ge.first ).to be_a IB::Stock
			expect( verified_ge.first.con_id ).to be_a Integer
			expect( verified_ge.first.contract_detail ).to be_a IB::ContractDetail


			expect{ verified_ge.first.save }.to change{ IB::Stock.count }.by 1
			expect( verified_ge.first.rid.rid?  ).to be_truthy
		end

		it "can be retrieved from the database" do
			rid =  IB::Stock.where( symbol: 'GE').first.rid
			database_ge =  V.get rid
			expect( database_ge.invariant_attributes ).to eq @ge.verify.first.invariant_attributes
		end


		it "updates the database upon saving" do
			verified_ge =  @ge.verify.first
			verified_ge.save
			expect( verified_ge.rid ).to eq IB::Stock.first.rid
		end
	end


end

