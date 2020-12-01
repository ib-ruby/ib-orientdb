require 'spec_helper'
require 'database_helper'

RSpec.shared_examples 'a valid orientdb database' do
		it { is_expected.to be_a ActiveOrient::OrientDB }
		its( :database_classes ){ is_expected.to include( "V").and include("E") }
end




RSpec.describe "Configuration::" do
	context "config file" do
		it "was correctyl read" do
				expect( OPTS.keys ).to eq [:verbose, :tws, :orient_db]
				expect( ACCOUNT ).to be_a String
		end
	end

	context "connect to database" do
		subject{ connect }
		it_behaves_like 'a valid orientdb database'
	end

	context "destroy the database" do
		before{ destroy_database }
		subject{ connect }
		it_behaves_like 'a valid orientdb database'
		its( :database_classes ){ is_expected.to eq [ "E","V"] } #  database in virgin state
		
	end
end
