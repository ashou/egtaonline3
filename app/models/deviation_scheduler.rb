class DeviationScheduler < Scheduler
  include PatternBasedScheduler

  def add_deviating_strategy(role_name, strategy)
    role = roles.where(name: role_name).first
    if role
      role.deviating_strategies += [strategy]
      role.save!
      ProfileAssociator.perform_async(id)
      if role.strategies.include? strategy
        self.remove_strategy(role_name, strategy)
      end
    end
  end

  def remove_deviating_strategy(role_name, strategy)
    role = roles.where(name: role_name).first
    if role && role.deviating_strategies.include?(strategy)
      role.deviating_strategies -= [strategy]
      role.save!
      ProfileAssociator.perform_async(id)
    end
  end

  def profile_space
    return [] if invalid_role_partition?
    subgame_assignments = SubgameCreator.subgame_assignments(roles)
    deviation_assignments = DeviationCreator.deviation_assignments(roles)
    AssignmentFormatter.format_assignments(
      (subgame_assignments + deviation_assignments).uniq)
  end
end
