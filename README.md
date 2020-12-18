# IB-OrientDB

---
__Documentation: [https://ib-ruby.github.io/ib-doc/](https://ib-ruby.github.io/ib-doc/)__  

__Questions, Contributions, Remarks: [Discussions are opened in ib-api](https://github.com/ib-ruby/ib-api/discussions)__

---

**[OrientDB](https://orientdb.org/)**  is a **N**ot **O**nly **SQL** Database owned and maintained by SAP.

It aims to be "the first Multi-Model Open Source NOSQL DBMS that brings together the power of graphs and the flexibility of documents into one scalable high-performance operational database."( [source](https://orientdb.org/docs/3.0.x/) )

**_IB-OrientDB_** connects a running [IB-api-client](https://github.com/ib-ruby/ib-api) to a running _OrientDB-Database-Server_ and provides 
methods to store data provided by the _Interactive Brokers TWS_ into the database and to retrieve  them as well. 

It replaces core functions of  **ib-gateway** from the [IB-Extensions-Gem](https://github.com/ib-ruby/ib-extensions)


## Store a contract in the database, query and ask the TWS for historical data

``` ruby
> ge =  IB::Stock.new symbol: 'GE'
> ge.verify.first.save              => <Stock: GE USD NYSE>
> puts IB::Stock.where(symbol: 'GE').eod( duration: 5).to_human
 #  INFO->MATCH {class: ib_stock, as: ib_stocks, where: ( symbol = 'GE') } RETURN ib_stocks
<Bar: 2020-11-23 wap 10.127 OHLC 9.76 10.27 9.76 10.25 trades 116355 vol 1025063>
<Bar: 2020-11-24 wap 10.574 OHLC 10.27 10.85 10.14 10.54 trades 204947 vol 1729882>
<Bar: 2020-11-25 wap 10.479 OHLC 10.55 10.6 10.34 10.51 trades 120367 vol 1063415>
<Bar: 2020-11-27 wap 10.403 OHLC 10.5 10.65 10.31 10.41 trades 73036 vol 529140>
<Bar: 2020-11-30 wap 10.215 OHLC 10.37 10.43 9.96 10.24 trades 134117 vol 1173670>


```




**Work in Progress**


