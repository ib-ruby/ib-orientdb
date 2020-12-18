module TG
	class Tag
		def portfolios
		  iz= out( HC::D2F ).compact.map( &:in ) # eliminates entries if no HC::D2F is detected
			iz unless iz.empty? # returns nil if no portfolio is detected
		end

		def self.portfolios
			query.nodes( :out, via: HC::D2F , expand: false)
		end
	end
end

# current_date.environment2(1).execute.portfolios.positions.contract
# INFO->select  expand ( $c ) let $a = (select from  ( traverse  inE('tg_grid_of').out  from #45:1869 while $depth <= 1  )  where $depth >=1 ), $b = (select from  ( traverse  outE('tg_grid_of').in  from #45:1869 while $depth <= 1  )  where $depth >=1 ), $c= UNIONALL($a,$b)  
# => [[["#186:0", "#202:0", "#203:0", "#188:1", "#204:0", "#194:0", "#187:0", "#189:0", "#190:0", "#191:0", "#192:0", "#186:2", "#206:0", "#207:0", "#208:0", "#195:0", "#187:1", "#193:0", "#186:1", "#209:0"]]]
