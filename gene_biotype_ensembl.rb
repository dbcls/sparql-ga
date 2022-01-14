require 'benchmark'
require 'sparql/client'
require "sparql"

# SPARQL
endpoint = "https://integbio.jp/togosite/sparql"
rq = <<'SPARQL'.chop
PREFIX obo: <http://purl.obolibrary.org/obo/>
PREFIX taxon: <http://identifiers.org/taxonomy/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX faldo: <http://biohackathon.org/resource/faldo#>
PREFIX dc: <http://purl.org/dc/elements/1.1/>

SELECT DISTINCT ?parent ?child ?child_label
FROM <http://rdf.integbio.jp/dataset/togosite/ensembl>
WHERE {
  ?enst obo:SO_transcribed_from ?ensg .
  ?ensg a ?parent ;
        obo:RO_0002162 taxon:9606 ;
        faldo:location ?ensg_location ;
        dc:identifier ?child ;
        rdfs:label ?child_label .
  FILTER(CONTAINS(STR(?parent), "terms/ensembl/"))
  BIND(STRBEFORE(STRAFTER(STR(?ensg_location), "GRCh38/"), ":") AS ?chromosome)
  VALUES ?chromosome {
      "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"
      "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22"
      "X" "Y" "MT"
  }
}
SPARQL

# puts "----"
# puts "オリジナルSPARQL:\n#{rq}"

client = SPARQL::Client.new(endpoint,
                            :method => :post)
# puts client.url

# 3.times do |i|
#   result = Benchmark.realtime do
#     rows = client.query(rq)
#     puts rows.size
#   end
#   puts "オリジナル#{i+1}: #{result}"
# end
# # 変換
# puts "-----"

sse = SPARQL.parse(rq)

pat = sse.operands[1].operands[1].operands[0].operands[1].operands[1].operands[0].operands[1].patterns
c=pat.permutation.to_a

c.each_with_index  {|cc,j|
  cc.each_with_index {|c1,i|
    pat[i]=c1
  }
  rqfromsse = "--"
  begin
    rqfromsse = sse.to_sparql()
    ## write rqfromsse to file
    File.open("gene_biotype_result/#{j}.txt", "w") do |f|
      f.puts rqfromsse
    end

    rowcount = -1
    result = Benchmark.realtime do
      rows = client.query(rqfromsse)
      rowcount = rows.size
    end
  rescue => e
    p e
  end
  puts "#{j},#{rowcount},#{result}"

}

