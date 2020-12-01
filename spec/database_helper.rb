require 'stringio'
require 'rspec/expectations'
require 'logger'

def	read_yml key
		YAML::load_file( File.expand_path('../../connect.yml',__FILE__))[key]
	end
def connect 
	orientdb =  read_yml(:orientdb)[:test] #.merge( logger: mock_logger )
	tws =  read_yml(:tws)[:test].merge( logger: mock_logger )
	Setup.connect tws: tws, orientdb: orientdb
end

=begin
Deletes the active database and unallocates ORD and DB
=end
def destroy_database

  connect
  Object.send :const_set, :ORD,     ActiveOrient::OrientDB.new(  preallocate:  false)
  ORD.delete_database database: read_yml(:orientdb)[:test][:database]
  ActiveOrient::Model.allocated_classes = {}
  Object.send :remove_const, :ORD 
  ActiveOrient::Model.allocated_classes = {}
	connect

end

def connect_tws
	tws =  read_yml(:tws)[:test].merge( logger: mock_logger )

	IB::Connection.new( **tws ) unless IB::Connection.current
end

## Logger helpers

def mock_logger
  @stdout = StringIO.new

  logger = Logger.new(@stdout).tap do |l|
    l.formatter = proc do |level, time, prog, msg|
      "#{time.strftime('%H:%M:%S')} #{msg}\n"
    end
    l.level = Logger::INFO
  end
end

def log_entries
  @stdout && @stdout.string.split(/\n/)
end


def should_log *patterns
  patterns.each do |pattern|
   expect( log_entries.any? { |entry| entry =~ pattern }).to be_truthy
  end
end

def should_not_log *patterns
  patterns.each do |pattern|
    expect( log_entries.any? { |entry| entry =~ pattern }).to be_falsey
  end
end


