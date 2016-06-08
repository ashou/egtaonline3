require 'spec_helper'

describe 'Users can make schedulers to schedule profiles' do
  before do
    sign_in
  end

  shared_examples 'a scheduler' do
    let(:klass) { described_class.to_s.tableize }

    describe 'creating a scheduler with modified configurationn',
             js: true do
      it 'makes the expected scheduler' do
        create(:simulator)
        other_simulator = create(:simulator)
        other_simulator.configuration = { 'parm1' => '14', 'parm2' => '6' }
        other_simulator.role_configuration = {
          'Role1' => %w(Strat1 Strat2),
          'Role2' => %w(Strat3 Strat4) }
        other_simulator.save!
        visit "/#{klass}/new"
        select other_simulator.fullname, from: 'selector_simulator_id'
        fill_in_with_hash(
          'Name' => 'test', 'Size' => 2,
          'Default observation requirement' => 10,
          'Observations per simulation' => 10, 'Process memory' => 1000,
          'Time per observation' => 40, 'Parm2' => 7)
        click_button 'Create Scheduler'
        expect(page).to have_content('Parm2: 7')
      end
    end

    describe 'adding a strategy or profile' do
      it 'adds a scheduling requirement' do
        simulator = create(:simulator, :with_strategies)
        simulator_instance = create(
          :simulator_instance,
          simulator_id: simulator.id, configuration: { 'fake' => 'value' })
        scheduler = create(
          described_class.to_s.underscore.to_sym,
          simulator_instance: simulator_instance)
        role = simulator.role_configuration.keys.last
        strategy = simulator.role_configuration[role].last
        visit "/#{klass}/#{scheduler.id}"
        select role, from: 'role'
        fill_in 'role_count', with: 2
        click_button 'Add Role'
        scheduler.reload
        if described_class != GenericScheduler
          click_link('Add Strategy', match: :first)
          expect(page).to have_content("Remove Strategy")
        else
          scheduler.add_profile("#{role}: 2 #{strategy}")
          visit "/#{klass}/#{scheduler.id}"
          expect(page).to have_content("#{role}: 2 #{strategy}")
        end
      end
    end

    describe 'removing a strategy or profile' do
      it 'removes a scheduling requirement' do
        simulator = create(:simulator, :with_strategies)
        simulator_instance = create(
          :simulator_instance,
          simulator: simulator,
          configuration: { 'fake' => 'value' })
        scheduler = create(
          described_class.to_s.underscore.to_sym,
          simulator_instance: simulator_instance)
        role = simulator.role_configuration.keys.last
        strategy = simulator.role_configuration[role].last
        if described_class != GenericScheduler
          scheduler.add_role(role, 2)
          scheduler.add_strategy(role, strategy)
          visit "/#{klass}/#{scheduler.id}"
          click_on 'Remove Strategy'
        else
          profile = scheduler.add_profile("#{role}: 2 #{strategy}")
          scheduler.remove_profile_by_id(profile.id)
          visit "/#{klass}/#{scheduler.id}"
        end
        expect(page).to_not have_content("#{role}: 2 #{strategy}")
      end
    end

    context 'when the scheduler has profiles' do
      let(:scheduler) do
        create(described_class.to_s.underscore.to_sym, :with_profiles)
      end
      let(:simulator_instance) { scheduler.simulator_instance }
      describe 'updating configuration of a scheduler' do
        it 'leads to new profiles being created' do
          assignment = simulator_instance.profiles.last.assignment
          visit "/#{klass}/#{scheduler.id}/edit"
          fill_in 'Parm2', with: 23
          click_button 'Update Scheduler'
          expect(page).to have_content('Parm2: 23')
          if described_class != GenericScheduler
            expect(page).to have_content(assignment)
            expect(Profile.count).to eq(simulator_instance.profiles.count * 2)
          else
            expect(page).to_not have_content(assignment)
            expect(Profile.count).to eq(simulator_instance.profiles.count)
          end
        end
      end

      describe 'updating default observation requirement' do
        it 'leads the counts on scheduling requirements to change' do
          unless scheduler.class == GenericScheduler
            count = scheduler.scheduling_requirements.first.count
            new_count = count + 5
            visit "/#{klass}/#{scheduler.id}/edit"
            fill_in 'Default observation requirement', with: new_count
            click_button 'Update Scheduler'
            expect(scheduler.reload.scheduling_requirements.first.count)
              .to eq(new_count)
          end
        end
      end
    end
  end

  SCHEDULER_CLASSES.each do |s_class|
    describe s_class do
      it_behaves_like 'a scheduler'
    end
  end
end
