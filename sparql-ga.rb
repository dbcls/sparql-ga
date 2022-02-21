require_relative 'ga'
require_relative 'chromosome'
require_relative 'sparqllib'
require 'fileutils'
require 'optparse'

# SPARQLGA class
class SPARQLGA < GeneticAlgorithm
  @@resultdirectory = "results"
  @@timestr = ''
  @@chr_size = -1
  @@number_of_trials = 3
  @@sparqlqueryfile = ''
  @@commandlinestring = ''
  def initialize(endpoint, sparqlqueryfile, leave_backslash: false, verbose: false, number_of_trials: 3, commandlinestring: '')
    @@endpoint = endpoint
    @@sparqlqueryfile = sparqlqueryfile
    @@sparqlquery = File.open(sparqlqueryfile, 'r') {|f| f.read}
    @@leave_backslash = leave_backslash
    @@number_of_trials = number_of_trials
    @@commandlinestring = commandlinestring
    SparqlChromosome.endpoint(@@endpoint)
    SparqlChromosome.leave_backslash(leave_backslash)
    SparqlChromosome.verbose(verbose)
    SparqlChromosome.number_of_trials(number_of_trials)
    @@chr_size = SparqlChromosome.rq(@@sparqlquery)

    @@verbose = verbose
    if verbose
      puts "Chromosome size: #{@@chr_size}"
    end
  end

  def generate(chromosome)
    value = (0..(@@chr_size - 1)).to_a.shuffle
    chromosome.new(value)
  end

  def chr_size
    @@chr_size
  end

  def select(population)
    # sort by fitness_value
    newary = population.sort! { |a, b| b.fitness_value <=> a.fitness_value }
    # sum of fitness_value for selection
    sum = newary.inject(0) { |sum, ch| sum + ch.fitness_value }
    # select parent 1
    p1rand = rand(0..sum)
    f = 0
    p1 = newary[0]
    newary.each do |ch|
      f += ch.fitness_value
      if f >= p1rand
        p1 = ch
        break
      end
    end
    # select parent 2
    # parent 2 is not the same as parent 1
    sum -= p1.fitness_value
    p2rand = rand(0..sum)
    f = 0
    p2 = newary[1]
    newary.each do |ch|
      next if ch == p1

      f += ch.fitness_value
      if f >= p2rand
        p2 = ch
        break
      end
    end
    [p1, p2]
  end

  def parse_only()
    sga = SparqlLib.new(@@endpoint, @@verbose)
    sga.set_original_query(@@sparqlquery)
    parseresult = sga.parse_only()
    parseresult = parseresult.gsub(/\\/, '') unless @@leave_backslash
    message = ''
    if @@verbose
      message = 'Parse result:\n'
    end
    puts "#{message}#{parseresult}"
  end

  def execute_only()
    sga = SparqlLib.new(@@endpoint, true)
    sga.set_original_query(@@sparqlquery)
    sga.exec_sparql_query(@@sparqlquery, @@number_of_trials)
  end

  def self.set_timestr_create_directory
    # create result directory
    if @@timestr == ''
      t = Time.now
      timestr = t.strftime('%Y%m%dT%H%M%S')
      @@timestr = timestr
      FileUtils.mkdir_p("#{@@resultdirectory}/#{timestr}/sparql")[0]
      FileUtils.mkdir_p("#{@@resultdirectory}/#{timestr}/time")[0]
      FileUtils.mkdir_p("#{@@resultdirectory}/#{timestr}/bestfit")[0]
      FileUtils.mkdir_p("#{@@resultdirectory}/#{timestr}/fastest")[0]
    end
  end

  def run(chromosome, p_cross, p_mutation, generations: 100, population_size: 100, include_original_order: false)
    # initialize reults directory
    self.class.set_timestr_create_directory
    FileUtils.cp(@@sparqlqueryfile, "#{@@resultdirectory}/#{@@timestr}/")
    # save command line string
    File.open("#{@@resultdirectory}/#{@@timestr}/commandline.txt", 'w') {|f| f.write(@@commandlinestring)}
    # Set result directoty information for SparqlChromosome
    SparqlChromosome.set_timestr_and_resultdirectory(@@timestr, @@resultdirectory)
    # initial population
    population = population_size.times.map { generate(chromosome) }
    # chromosome.new(value)
    population[0] = chromosome.new((0..(@@chr_size - 1)).to_a) if include_original_order
    current_generation = population
    next_generation    = []
    alltime_best = population[0]

    generations.times do |cnt|
      puts "Generation #{cnt}" if @@verbose
      # Exec fitness function
      current_generation.each { |ch| ch.fitness }

      # max
      best_fit = current_generation.max_by { |ch| ch.fitness_value }.dup

      if best_fit.fitness_value > alltime_best.fitness_value
        alltime_best = best_fit.dup
      end

      puts "Best fit: #{best_fit.value} => #{best_fit.fitness_value}, elapsed time: #{best_fit.elapsed_time}" if @@verbose
      (population.size / 2).times do
        selection = select(current_generation)
        # crossover
        selection = crossover(selection, chromosome)
        # mutation
        selection[0].mutate(p_mutation)
        selection[1].mutate(p_mutation)
        # set next generation
        next_generation << selection[0] << selection[1]
      end
      # NOTE: last generation is not evaluated
      current_generation = next_generation
      next_generation    = []
      # save best fit
      File.open("#{@@resultdirectory}/#{@@timestr}/bestfit/#{cnt}_bestfit.txt", 'w') { |f| f.write("All times Best fit: Chr #{alltime_best.value} => #{alltime_best.fitness_value}, elapsed time: #{alltime_best.elapsed_time}") }
      # save fastest fit
      File.open("#{@@resultdirectory}/#{@@timestr}/fastest/#{cnt}_fastest.txt", 'w') { |f| f.write("All times Fastest fit: Chr #{SparqlChromosome.fastest_chromosome} => #{SparqlChromosome.fastest_fitness}, elapsed time: #{SparqlChromosome.fastest_time}") }
    end

    # return best solution
    puts "All times Best fit: Chr #{alltime_best.value} => #{alltime_best.fitness_value}, elapsed time: #{alltime_best.elapsed_time}"
    puts "All times Fastest fit: Chr #{SparqlChromosome.fastest_chromosome} => #{SparqlChromosome.fastest_fitness}, elapsed time: #{SparqlChromosome.fastest_time}"

    "#{alltime_best.value} => #{alltime_best.fitness_value}, elapsed time: #{alltime_best.elapsed_time}"
  end

  # Croossover method  is OX
  def crossover(selection, chromosome)
    i1 = rand(0..@@chr_size - 1)
    i2 = rand(i1..@@chr_size - 1)

    return selection if i1 == i2

    a1 = selection[0].value
    a2 = selection[1].value
    cr1 = Array.new(@@chr_size, -1)
    cr2 = Array.new(@@chr_size, -1)
    i1.upto(i2) do |i|
      cr1[i] = a1[i]
      cr2[i] = a2[i]
    end
    s1 = a2 - cr1
    s2 = a1 - cr2
    0.upto(s1.size - 1) do |i|
      cr1[(i2 + 1 + i) % @@chr_size] = s1[i]
      cr2[(i2 + 1 + i) % @@chr_size] = s2[i]
    end

    [chromosome.new(cr1), chromosome.new(cr2)]
  end
end

# SPARQL Chromosome class
class SparqlChromosome < Chromosome
  @@output_sparql_directory = ''
  @@output_time_directory = ''
  @@output_timearray_directory = ''

  @@fitness_value_cache = {}
  @@elapsed_time_cache = {}

  @@number_of_trials = 3

  @@alltime_best_fitness_value = -1
  @@alltime_best_resulttime = -1
  @@alltime_best_value = []

  @@leave_backslash = false
  @@verbose = false

  def self.leave_backslash(leave_backslash)
    @@leave_backslash = leave_backslash
  end

  def self.endpoint(endpoint)
    @@endpoint = endpoint
  end

  def self.rq(rq)
    @@rq = rq
    find_chr_size
  end

  def self.verbose(verbose)
    @@verbose = verbose
  end

  def self.number_of_trials(number_of_trials)
    @@number_of_trials = number_of_trials
  end

  def self.find_patterns(object)
    if object.respond_to?(:patterns)
      # TODO : check if patterns is only one
      @patternsobject = object.patterns
    elsif object.respond_to?(:operands)
      object.operands.each do |x|
        find_patterns(x)
      end
    end
  end

  def self.find_chr_size
    @sse = SPARQL.parse(@@rq)
    find_patterns(@sse)
    # length of pattersobject
    @patternsobject.size
  end

  # executed sparql
  @executed_sparql = ''
  # timestr
  @@timestr = ''
  def self.set_timestr_and_resultdirectory(timestr, resultdirectory)
    @@timestr = timestr
    @@output_sparql_directgory = "#{resultdirectory}/#{timestr}/sparql"
    @@output_timearray_directory = "#{resultdirectory}/#{timestr}/time/"
  end

  def initialize(value)
    super(value)
    # set timestr
    #self.class.set_timestr
    # record all execution time
    @resulttimearray = []
  end

  def fitness
    # check result is in cached
    if @@fitness_value_cache.has_key?(@value)
      @fitness_value = @@fitness_value_cache[@value]
      @elapsed_time = @@elapsed_time_cache[@value]
      return @fitness_value
    end
    sga = SparqlLib.new(@@endpoint, @@verbose)
    sga.set_original_query(@@rq)
    puts "Chr: #{@value}" if @@verbose
    @executed_sparql = sga.create_new_querystring(@value)
    # remove backslash
    @executed_sparql = @executed_sparql.gsub(/\\/, '') if not @@leave_backslash
    @resulttimearray = sga.exec_sparql_query(@executed_sparql, @@number_of_trials)
    sortedsort = @resulttimearray.dup
    sortedsort.sort!
    @resulttime = sortedsort[sortedsort.size / 2]

    if @resulttime == -1
      @fitness_value = 0
    else
      @fitness_value = 1 / @resulttime
    end
    # record all time best
    fastest_time = sortedsort[0]
    fastest_fit = 1 / fastest_time
    if @@alltime_best_fitness_value < fastest_fit
      @@alltime_best_fitness_value = fastest_fit
      @@alltime_best_resulttime = fastest_time
      @@alltime_best_value = @value
    end
    @@fitness_value_cache[@value] = @fitness_value
    @@elapsed_time_cache[@value] = @resulttime
    save_result
    @fitness_value
  end

  def mutate(probability_of_mutation)
    value.each_with_index do |x, i|
      next if rand > probability_of_mutation

      pos = rand(0..(SIZE - 1))
      @value[i] = @value[pos]
      @value[pos] = x
    end
  end

  def save_result
    # file prefix made by chromosome value
    prefix = @value.join('_')
    # save result

    File.open("#{@@output_sparql_directgory}/#{prefix}.rq", 'w') do |f|
      f.puts @executed_sparql
    end
    # save elapsed time array
    File.open("#{@@output_timearray_directory}/#{prefix}.time.txt", 'w') do |f|
      f.puts @resulttimearray.join(',')
    end
  end

  def elapsed_time
    @@elapsed_time_cache[@value]
  end

  def self.fastest_time
    @@alltime_best_resulttime
  end

  def self.fastest_fitness
    @@alltime_best_fitness_value
  end

  def self.fastest_chromosome
    @@alltime_best_value
  end
end

# main
commandlinestring = ["#{$0}", ARGV].join(" \\\n")

opts = ARGV.getopts('', 'verbose', 'sparqlquery:', 'endpoint:', 'population-size:4', 'generations:2',
                    'number-of-trials:3', 'leave-backslash', 'parse-only', 'execute-only')
if opts['verbose']
  puts opts
  puts opts['endpoint']
end
if opts['endpoint'].nil?
  puts 'Please specify endpoint'
  exit
end
if opts['sparqlquery'].nil?
  puts 'Please specify sparql query file'
  exit
end

ga = SPARQLGA.new(opts['endpoint'], opts['sparqlquery'], leave_backslash: opts['leave-backslash'], verbose: opts['verbose'],  number_of_trials: opts['number-of-trials'].to_i, commandlinestring: commandlinestring)
if opts['parse-only']
  ga.parse_only
  exit
end
if opts['execute-only']
  ga.execute_only
  exit
end

ga.run(SparqlChromosome, 0.2, opts['mutation-probability'].to_f, generations: opts['generations'].to_i, population_size: opts['population-size'].to_i)
