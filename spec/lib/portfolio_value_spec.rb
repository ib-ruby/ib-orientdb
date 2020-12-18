require 'spec_helper'
require 'database_helper'

	def sample_contracts # returns an array of allocated contracts
	  @sc ||=	["GE", 'T', 'M', 'V'].map{|x| IB::Contract.new( symbol: x, con_id: rand(9999) ).save}
	end
  def sample_portfolio_values

    sample_contracts.map do |sc|
		  IB::PortfolioValue.new(	 contract: sc, market_value: rand(9999),
														   reallized_pnl: 0, unrealized_pnl: rand(999) )
		end
	end



RSpec.describe 'HC::Portfolio' do
	before(:all) do
		 connect  
		 HC::Portfolio.delete all: true
		 IB::Contract.delete all: true
		 IB::PortfolioValue.delete all: true
#		 gateway =  IB::OrientGateway.current
		 p = HC::Portfolio.new
		 p.save
	 p.import_positions from: sample_portfolio_values
	end

	context "check environment" do
		let( :portfolio ){ HC::Portfolio.last }	
		it { expect( HC::Portfolio.count).to eq 1 }
		it { puts portfolio.inspect }
		it "has account_values" do
			expect( portfolio.out.count ).to eq 4
			
		end

		context "fetch positions and contracts" do
			subject { HC::Portfolio.last }
		
			its( :out ){is_expected.to be_a Array}
			it{ expect( portfolio.out.count).to eq 4}
			it{ expect( portfolio.positions.size ).to  eq 4 }
			it  "access contracts" do
				contract_rids =  sample_contracts.map &:rid
			 expect( portfolio.positions.map{ |y| y.contract.rid }).to  eq contract_rids
			
			end
		end

		context "assign to the time-grid  and analyse " do
      before(:all) do

		    # this is a copy of the assignment in Portfoliot#bake
				"1.5.2010".to_tg.assign vertex: HC::Portfolio.last, via: HC::D2F
			end

			let(:current_portfolio) { HC::Portfolio.last }
      let(:current_date){"1.5.2010".to_tg}
			it " the portfolio is assigned to the date-grid" do
				expect( current_date.portfolios ).to be_an( Array).and( have(1).item )
				expect( current_date.portfolios.first ).to eq current_portfolio
			  expect( current_portfolio.in ).to be_an(Array).and( have(1).item )
				expect( current_portfolio.in(HC::D2F).out ).to be_an(Array).and( have(1).item )
				expect( current_portfolio.in(HC::D2F).out.first ).to eq current_date
				expect( current_portfolio.out(HC::HAS_POSITION).in ).to  be_an(Array).and( have(4).items )
			end
      

			it "a date-range accesses the portfolio"  do
				expect( current_date.environment(5)).to be_a OrientSupport::Array 
				expect( current_date.environment(5)).to have(11).items 
				current_date.environment(5).each{|x| expect( x).to be_a  TG::Tag } 
				current_date.environment(5).portfolios.compact.each{|x| x.each{ |y| expect( y).to be_a HC::Portfolio }} 
				# In this test, only one portfolio is present
				expect( current_date.environment(5).portfolios.compact).to have(1).item.and( eq current_portfolio )
				expect( current_date.environment(5).out(HC::D2F).in.out( HC::HAS_POSITION ).in.orient_flatten.count ).to eq 4
				# portfolio.positions is the same then out(HC::D2F).in.out( HC::HAS_POSITION ).in.
				expect( current_date.environment(5).portfolios.positions.orient_flatten.count ).to eq 4


			end
		end

	end

end
