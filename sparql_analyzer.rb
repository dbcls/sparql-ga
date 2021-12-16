# coding: utf-8
#lib = File.expand_path('./lib', __FILE__)
#$LOAD_PATH.push('./')
$LOAD_PATH.push('./lib')
#p $LOAD_PATH
require "linkeddata"
require "rubygems"
require "sparql"


# SPARQL入門
# https://www.aise.ics.saitama-u.ac.jp/~gotoh/IntroSPARQL.html



# read file to sp , filename given as argument
filename = ARGV[0]
sp = File.open(filename, "r") {|f| f.read}

def walk(ar,level=0)
  puts "---"
  if ar.respond_to?(:each)
    ar.each do |x|
      puts "  "*level+"X :" + x.to_s
      puts "  "*level+"x.class: " + x.class.to_s
      if x.kind_of?(RDF::Query) 
        puts "x.to_sxp: " + x.to_sxp
        puts "  "*level+"x.class: " + x.class.to_s
        x.patterns.each do |p|
          # puts p.instance_of?(RDF::Query::Pattern)
          # puts p.instance_of?(RDF::Query)
          puts "  "*level+" p.class: " + p.class.to_s
          puts "  "*level+" p.to_sxp: " + p.to_sxp
        end
      end
        # puts x
      walk(x,level+1)
    end
    if ar.respond_to?(:operands)
      if ar.kind_of?(RDF::Query) 
        # ar is RDF::Query
        pass
      end
    end
  else
    # puts "ar.class: #{ar.class}"
    if ar.kind_of?(RDF::Query) 
      puts "ar.to_sxp: " + ar.to_sxp
    end
  end
end

puts "SPARQL: #{sp}"
puts "---"
sse = SPARQL.parse(sp)
puts sse.class
puts "sse.class : #{sse.class}"
puts "SPARQL.parse: #{sse}"
# puts sse
puts "--- sse.to_sxp"
puts sse.to_sxp
puts "--- end sse.to_sxp"
# check sse has operands
if sse.respond_to?(:operands)
pat = sse.operands
  pat.each do |p|
    walk(p)
  end
end
