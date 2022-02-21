# frozen_string_literal: true

# Chromosome class
class Chromosome
  NOT_IMPLEMENT_YET = 'Not implemented yet'

  attr_reader :value, :fitness_value

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

  def chr
    @value
  end

end
