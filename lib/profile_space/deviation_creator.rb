require_relative 'role_combination_generator'

class DeviationCreator
  def self.deviation_assignments(roles)
    assignments = []
    combination_tracker = {}
    roles.each do |role|
      assignments.concat(deviations_from_role(
        role, roles, combination_tracker))
    end
    assignments.uniq
  end

  def self.deviations_from_role(target_role, roles, combination_tracker)
    role_combinations = roles.map do |role|
      if role == target_role
        deviation_role_combinations(role)
      else
        combination_tracker[role] ||= RoleCombinationGenerator.combinations(
          role.name, role.strategies, role.reduced_count)
      end
    end
    role_combinations[0].product(*(role_combinations.drop(1)))
  end

  def self.deviation_role_combinations(role)
    combinations = []
    RoleCombinationGenerator.combinations(
      role.name, role.strategies, role.reduced_count - 1).each do |combination|
      role.deviating_strategies.each do |s|
        combinations << fill_last_strategy(combination, s)
      end
    end
    combinations.uniq
  end

  def self.fill_last_strategy(combination, strategy)
    role = combination[0]
    strategies = combination.drop(1)
    strategies << strategy
    [role].concat(strategies.sort)
  end
end
