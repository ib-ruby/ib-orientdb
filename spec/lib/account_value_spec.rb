require 'spec_helper'
require 'database_helper'

  def sample_account_values
		[ IB::AccountValue.new(	:key=>:AccountCode, :value=>"U17612", :currency=>""),
		IB::AccountValue.new( :key=>:AccountOrGroup, :value=>"Evelyn", :currency=>"BASE"	),
		IB::AccountValue.new(	:key=>:AccruedCash, :value=>"5.00", :currency=>"AUD"),
		IB::AccountValue.new(	:key=>:AccruedCash, :value=>"-5.1914397", :currency=>"BASE"),
		IB::AccountValue.new(	:key=>:AccruedCash, :value=>"0.00", :currency=>"EUR"),
		IB::AccountValue.new( :key=> :NetLiquidation, value: "71676.21", :currency=>"EUR"),
		IB::AccountValue.new( :key=> :"NetLiquidation-C", :value=> "5713.49", :currency=>"EUR"),
		IB::AccountValue.new( :key=> :"NetLiquidation-F", :value=> "31517.21", :currency=>"EUR"),
		IB::AccountValue.new( :key=> :"NetLiquidation-S", :value=> "34445.49", :currency=>"EUR") ]
	end




RSpec.describe 'HC::Portfolio' do
	before(:all) do
		 connect  
		 HC::Portfolio.delete all: true

#		 gateway =  IB::OrientGateway.current
		 @p = HC::Portfolio.new
		 @p.import_account_data from: sample_account_values
	end

	context "check environment" do

		it "has account_values" do
			expect( @p.values ).to be_a Hash
		end
		it "Account Values without numeric values are omitted" do
			expect( @p.values.keys ).to eq [:AccruedCash,:NetLiquidation]
		end
 
		## format:  values[:key]{:ALL => { :EUR => 00.00, :USD => 00.00, ... }, :C => { :EUR => 00.00 }, ... 
    it " sepearate subaccounts are translated to sub-hashes" do
			expect( @p.values[:NetLiquidation].keys ).to eq [ :ALL, :C, :F, :S ]
		end

		## format:  values[:key][:ALL]{ :EUR => 00.00, :USD => 00.00, ... }
		it "different currencies are present in sub-hashes" do
			expect(@p.values[:AccruedCash].keys).to eq [:ALL]
			expect(@p.values[:AccruedCash][:ALL].keys).to eq [:AUD,:BASE]
		end
	end

	context "fetch content" do
		it "Get values via regex" do
			expect( @p.values.slice /Acc/  ).to eq :AccruedCash=>{:ALL=>{:AUD=>5.0, :BASE=>-5.1914397}}
		end
	end

end
