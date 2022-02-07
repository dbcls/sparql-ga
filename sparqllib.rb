require 'benchmark'
require 'sparql/client'
require 'sparql'
require 'parallel'

# SPARQLGA library class
class SparqlLib
  def initialize(endpoint)
    @endpoint = endpoint
    @client = SPARQL::Client.new(@endpoint,
                                 method: :post)
  end

  def set_original_query(rq)
    @rq = rq
    @sse = SPARQL.parse(@rq)
    # TODO: update not hard coding version
    @pat = @sse.operands[1].operands[1].operands[0].operands[1].operands[1].operands[0].operands[1].patterns.clone
  end

  def create_new_querystring(order)
    # c=pat.permutation.to_a
    index = 0
    order.each do |i|
      @sse.operands[1].operands[1].operands[0].operands[1].operands[1].operands[0].operands[1].patterns[index] =
        @pat[i]
      index += 1
    end
    rqfromsse = ''
    begin
      rqfromsse += @sse.to_sparql
      ## write rqfromsse to file
      # File.open("gene_biotype_result2/#{j}.rq", "w") do |f|
      #     f.puts rqfromsse
      # end
    rescue StandardError => e
      p e
    end
    rqfromsse
  end

  def display_rows(rows)
    puts "Number of rows: #{rows.size}"
    rows.each do |row|
      row.each do |key, val|
        # print "#{key.to_s.ljust(10)}: #{val}\t"
        print "#{key}: #{val}\t"
      end
      print "\n"
    end
  end

  def exec_sparql_query(querystring, attemps)
    # construct SPARQL query
    # DEFINE is used to save order of query
    rq = "DEFINE sql:select-option \"order\"\n"
    rq += querystring
    # result has time
    result = -1
    rl = [-1] * attemps
    rowcount = -1
    Parallel.map(1..attemps) do |item|
      result = -1
      begin
        result = Benchmark.realtime do
          rows = @client.query(rq)
          rowcount = rows.size
        end
        puts "#{item}, #{rowcount}, #{result}"
      # p [item, rowcount, result]
      rescue StandardError
        # p [item, -1, -1]
      end
      result
    end
  end
end
