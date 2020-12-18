class Array
  # enables calling members of an array. which are hashes  by it name
  # i.e
  #
  #  2.5.0 :006 > C.received[:OpenOrder].local_id
  #   => [16, 17, 21, 20, 19, 8, 7] 
  #   2.5.0 :007 > C.received[:OpenOrder].contract.to_human
  #    => ["<Bag: IECombo SMART USD legs:  >", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: GE USD>", "<Stock: WFC USD>", "<Stock: WFC USD>"] 
  #
  # its included temporary 
	#
	# to_do: substitute with a delegation solution

  def method_missing(method, *key)
    unless method == :to_hash || method == :to_str #|| method == :to_int
      return self.compact.map{|x| x.public_send(method, *key)}
    end

  end
end # Array

