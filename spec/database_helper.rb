require 'stringio'
require 'rspec/expectations'
require 'logger'

def	read_yml key
		YAML::load_file( File.expand_path('../../connect.yml',__FILE__))[key]
	end
def connect 
	project_root = File.expand_path('../..', __FILE__)
	model_dir =  project_root + '/lib/models'
	puts "model_dir: #{model_dir}"

	orientdb =  read_yml(:orientdb)[:test] #.merge( logger: mock_logger )
	tws =  read_yml(:tws)[:test].merge( logger: mock_logger )
	ActiveOrient::Model.model_dir = model_dir
	ActiveOrient::Model.keep_models_without_file =  false

	IB::Setup.connect tws: tws, orientdb: orientdb
	ActiveOrient::Init.define_namespace { HC  }
	ActiveOrient::OrientDB.new
	
end

=begin
Deletes entries of the active database
=end
def clear_database
	

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


