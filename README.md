# sparql-query-analyzer

Optimize SPARQL Query.

## Dependencies

- ruby 3
- [ruby\-rdf/sparql: Ruby SPARQL library](https://github.com/ruby-rdf/sparql)
- [grosser/parallel: Ruby: parallel processing made simple and fast](https://github.com/grosser/parallel)
  - 1.21.0

## Install required gem

```console
bundle install --path vendor/bundle
```

## How to execute

- `--endpoint`
  - SPARQL endpoint
- `--sparqlquery`
  - SPARQL query
- Optional
  - `--population_size`
    - Population size (default: 4)
  - `--generations`
    - Number of generations (default: 2)
  - `--mutation_probability`
    - Probability of mutaion (default: 0.01)
  - `number_of_trials` (default: 3)
    - Number of trials per each indivisual's evaluation

```console
bundle exec ruby sparqlga.rb --endpoint="http://dev.togogenome.org/sparql" \
  --sparqlquery=sample5.rq --population_size=100 \
  --generations=50
```

## Develop Machine Environment

- ruby 3.0.3p157 (2021-11-24 revision 3fb7d2cadc) [x86_64-darwin20]
  - This ruby is installed via rbenv
