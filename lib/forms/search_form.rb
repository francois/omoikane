require "reform"
require "forms/project_form"
require "forms/query_form"

class SearchForm < Reform::Form
  property :query,    writeable: false

  property :queries,  writeable: false
  property :projects, writeable: false
  property :results,  writeable: false
end
