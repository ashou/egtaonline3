# Updating ControlVariables and PlayerControlVariables means that affected
# adjusted payoffs need to be updated to match.  The locking and isolation here
# is because new data could be arriving while the update occurs, and we want to
# make sure that all data gets the update.

class ControlVariateUpdater
  def self.update(control_vars, player_control_vars)
    binds = []
    ActiveRecord::Base.exec_sql(
      "BEGIN ISOLATION LEVEL SERIALIZABLE;\n" +
      control_vars.map do |id, values|
        binds.concat([values['expectation'].to_f, id.to_i])
        "UPDATE control_variables SET expectation = ? WHERE id = ?;\n" +
        values['role_coefficients'].map do |id, values|
          binds.concat([values['coefficient'].to_f, id.to_i])
          "UPDATE role_coefficients SET coefficient = ? WHERE id = ?;\n"
        end.join('')
      end.join('') +
      player_control_vars.map do |id, values|
        binds.concat([values['coefficient'].to_f, values['expectation'].to_f,
                      id.to_i])
        "UPDATE player_control_variables SET coefficient = ?, " \
        "expectation = ? WHERE id = ?;\n"
      end.join('') +
      'COMMIT;', *binds)
  end
end
