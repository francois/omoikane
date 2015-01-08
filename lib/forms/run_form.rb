require "reform"

class RunForm < Reform::Form
  property :subtitle
  property :submitter

  validates :subtitle, :submitter, presence: true

  def project
    model.project
  end

  def project_id
    project.project_id
  end

  def project_title
    project.title
  end

  def project_instructions
    project.instructions
  end

  def queries
    project.queries
  end

  def number_of_queries
    queries.size
  end

  def parameters
    build_default_parameters
  end

  def build_default_parameters
    names = queries.map(&:sql).map do |sql|
      sql.scan(/[^:]:\w+\b/).map{|str| str[1..-1]}
    end.flatten.uniq.sort_by do |key|
      num = 100
      num += 10 if key =~ /_on$/
      num += 20 if key =~ /_at$/
      num +=  1 if key =~ /start/
      num +=  5 if key =~ /end/
      [num, key]
    end

    names.each_with_object(Hash.new) do |name, memo|
      memo[name] = "?"
    end
  end
end
