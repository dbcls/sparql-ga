class Chromosome
  NOT_IMPLEMENT_YET = "Not implemented yet"
  # TODO: not use constant
  SIZE = 6

  attr_reader :value

  # higher fitness_value is better
  @fitness_value = 0

  def initialize(value)
    @value = value
  end

  def fitness
    # Implement in subclass
    1
  end

  def [](index)
    @value[index]
  end

  def mutate(probability_of_mutation)
    @value = value.map { |ch| rand < probability_of_mutation ? invert(ch) : ch }
  end

  def get_chr
    return @value
  end
  def get_fitness_value
    return @fitness_value
  end
    
end