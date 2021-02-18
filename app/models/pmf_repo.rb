class PmfRepo
  DEFAULT_WINDOW = 1 # week

  def self.state(state_name, start_date, end_date, window = DEFAULT_WINDOW)
    week_start_dates = (start_date.to_date..end_date.to_date).map(&:beginning_of_week).uniq

    week_start_dates.map do |start_date|
      end_date = start_date + 1.week
      states = states_for_window_dates(start_date, end_date)

      state_groups = {}

      states.sort_by{|u| [-u[1], u[0]]}.each do |u|
        next unless u[2] == state_name
        state_groups[u[2]] ||= []
        state_groups[u[2]] << {repo_name: u[0], score: u[1]}
      end

      {date: start_date, states: state_groups}
    end
  end

  def self.states_summary(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    week_start_dates = (start_date.to_date..end_date.to_date).map(&:beginning_of_week).uniq

    week_start_dates.map do |start_date|
      end_date = start_date + 1.week
      states = states_for_window_dates(start_date, end_date)
      state_groups = Hash[states.group_by{|u| u[2]}.map{|s,u| [s, u.length]}]
      {date: start_date, states: state_groups}
    end
  end

  def self.transitions(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    week_start_dates = (start_date.to_date..end_date.to_date).map(&:beginning_of_week).uniq

    periods = week_start_dates.map do |start_date|
      end_date = start_date + 1.week
      states = states_for_window_dates(start_date, end_date)
      {date: start_date, states: states}
    end

    # for each window, compare states between repos and add to transition bucket
    previous_period = nil
    transition_periods = []

    periods.each_with_index do |period,i|
      if i.zero?
        previous_period = period
        next
      end
      # note - not calculating 11 -	Never Used

      # 1 	First Time               (currently in first)

      # 2 	Bounced                  (first -> inactive)
      # 3 	New Low-Value            (first -> low)
      # 4 	New High-Value           (first -> high)
      # 5 	Reactivated Low-Value    (inactive -> low)
      # 6 	Low to High-Value        (low -> high)
      # 7 	High to Low-Value        (high -> low)
      # 8 	Lapsed Low-Value         (low -> inactive)
      # 9 	Reactivated High-Value   (inactive -> high)
      # 10 	Lapsed High-Value        (high -> inactive)
      # 12 	High-Value               (high -> high)
      # 13 	Low-Value                (low -> low)
      # 14 	Inactive                 (inactive -> inactive)

      previous_states = Hash[previous_period[:states].group_by{|u| u[2] }.map{|s,repos| [s, repos.map{|u| u[0] }]}]
      current_states = Hash[period[:states].group_by{|u| u[2] }.map{|s,repos| [s, repos.map{|u| u[0] }]}]

      bounced = compare_states(previous_states, current_states, 'first', 'inactive')
      new_low = compare_states(previous_states, current_states, 'first', 'low')
      new_high = compare_states(previous_states, current_states, 'first', 'high')
      reactive_low = compare_states(previous_states, current_states, 'inactive', 'low')
      low_high = compare_states(previous_states, current_states, 'low', 'high')
      high_low = compare_states(previous_states, current_states, 'high', 'low')
      reactive_high = compare_states(previous_states, current_states, 'inactive', 'high')
      lapsed_low = compare_states(previous_states, current_states, 'low', 'inactive')
      lapsed_high = compare_states(previous_states, current_states, 'high', 'inactive')
      high = compare_states(previous_states, current_states, 'high', 'high')
      low = compare_states(previous_states, current_states, 'low', 'low')
      inactive = compare_states(previous_states, current_states, 'inactive', 'inactive')

      transition_periods << {
        date: period[:date],
        transitions: {
          'First Time': current_states['first'].length,
          'Bounced': bounced.length,
          'New Low-Value': new_low.length,
          'New High-Value': new_high.length,
          'Reactivated Low-Value': reactive_low.length,
          'Low to High-Value': low_high.length,
          'High to Low-Value': high_low.length,
          'Lapsed Low-Value': lapsed_low.length,
          'Reactivated High-Value': reactive_high.length,
          'Lapsed High-Value': lapsed_high.length,
          'High-Value': high.length,
          'Low-Value': low.length,
          'Inactive': inactive.length
        }
      }
      previous_period = period
    end

    return transition_periods
  end

  def self.transitions_with_details(start_date, end_date, window = DEFAULT_WINDOW)
    window = DEFAULT_WINDOW if window.nil?
    return unless window >= 1

    week_start_dates = (start_date.to_date..end_date.to_date).map(&:beginning_of_week).uniq

    periods = week_start_dates.map do |start_date|
      end_date = start_date + 1.week
      states = states_for_window_dates(start_date, end_date)
      {date: start_date, states: states}
    end

    # for each window, compare states between users and add to transition bucket
    previous_period = nil
    transition_periods = []

    periods.each_with_index do |period,i|
      if i.zero?
        previous_period = period
        next
      end
      # note - not calculating 11 -	Never Used

      # 1 	First Time               (currently in first)

      # 2 	Bounced                  (first -> inactive)
      # 3 	New Low-Value            (first -> low)
      # 4 	New High-Value           (first -> high)
      # 5 	Reactivated Low-Value    (inactive -> low)
      # 6 	Low to High-Value        (low -> high)
      # 7 	High to Low-Value        (high -> low)
      # 8 	Lapsed Low-Value         (low -> inactive)
      # 9 	Reactivated High-Value   (inactive -> high)
      # 10 	Lapsed High-Value        (high -> inactive)
      # 12 	High-Value               (high -> high)
      # 13 	Low-Value                (low -> low)
      # 14 	Inactive                 (inactive -> inactive)

      previous_states = Hash[previous_period[:states].group_by{|u| u[2] }]
      current_states = Hash[period[:states].group_by{|u| u[2] }]

      bounced = compare_states_with_details(previous_states, current_states, 'first', 'inactive')
      new_low = compare_states_with_details(previous_states, current_states, 'first', 'low')
      new_high = compare_states_with_details(previous_states, current_states, 'first', 'high')
      reactive_low = compare_states_with_details(previous_states, current_states, 'inactive', 'low')
      low_high = compare_states_with_details(previous_states, current_states, 'low', 'high')
      high_low = compare_states_with_details(previous_states, current_states, 'high', 'low')
      reactive_high = compare_states_with_details(previous_states, current_states, 'inactive', 'high')
      lapsed_low = compare_states_with_details(previous_states, current_states, 'low', 'inactive')
      lapsed_high = compare_states_with_details(previous_states, current_states, 'high', 'inactive')
      high = compare_states_with_details(previous_states, current_states, 'high', 'high')
      low = compare_states_with_details(previous_states, current_states, 'low', 'low')
      inactive = compare_states_with_details(previous_states, current_states, 'inactive', 'inactive')

      transition_periods << {
        date: period[:date],
        transitions: {
          'First Time': current_states['first'].map{|u| {repo_name: u[0], score: u[1], previous: 0} } || [],
          'Bounced': bounced,
          'New Low-Value': new_low,
          'New High-Value': new_high,
          'Reactivated Low-Value': reactive_low,
          'Low to High-Value': low_high,
          'High to Low-Value': high_low,
          'Lapsed Low-Value': lapsed_low,
          'Reactivated High-Value': reactive_high,
          'Lapsed High-Value': lapsed_high,
          'High-Value': high,
          'Low-Value': low,
          'Inactive': inactive
        }
      }
      previous_period = period
    end

    return transition_periods
  end

  def self.transition(transition_name, start_date, end_date, window = DEFAULT_WINDOW)
    periods = transitions(start_date, end_date, window)
    periods.map do |period|
      {
        date:  period[:date],
        transitions: period[:transitions].slice(transition_name.to_sym)
      }
    end
  end

  def self.transition_with_details(transition_name, start_date, end_date, window = DEFAULT_WINDOW)
    periods = transitions_with_details(start_date, end_date, window)
    periods.map do |period|
      {
        date:  period[:date],
        transitions: period[:transitions].slice(transition_name.to_sym)
      }
    end
  end

  private

  def self.compare_states(previous_states, current_states, previous_group, current_group)
    prev = previous_states[previous_group] || []
    curr = current_states[current_group] || []
    prev & curr
  end

  def self.compare_states_with_details(previous_states, current_states, previous_group, current_group)
    prev = previous_states[previous_group] || []
    curr = current_states[current_group] || []
    names = prev.map(&:first) & curr.map(&:first)
    curr.select{|u| names.include?(u[0])}.sort_by{|u| [-u[1], u[0]] }.map do |u|
      pscore = prev.find{|pu| pu[0] == u[0] }.try(:second) || 0
      {repo_name: u[0], score: u[1], previous: pscore}
    end
  end

  def self.states_for_window_dates(start_date, end_date)
    Rails.cache.fetch(['pmf_repo_states_for_window_dates', start_date, end_date], expires_in: 1.week) do
      puts "Generating cache for #{start_date} - #{end_date}"
      window_events = load_event_data(start_date, end_date)

      previous_repo_names = previously_active_repo_names(start_date)

      active_repos = window_events.group_by(&:repository_full_name)

      scores = active_repos.map{|repo_name, events| [repo_name, score_for_repo(repo_name, events)] }

      states = scores.map{|repo_name, score| [repo_name, score, state_for_repo(repo_name, score)] }

      these_repos = states.map{|a| a[0]}

      # repo from previous_repo_names not present here (inactive)
      inactive = previous_repo_names - these_repos
      states += inactive.map{|repo_name| [repo_name, 0, 'inactive'] }

      # repo not in previous_repo_names present here (first)
      first = these_repos - previous_repo_names

      states.map do |repo|
        first.include?(repo[0]) ? [repo[0], repo[1], 'first'] : repo
      end
    end
  end

  def self.score_for_repo(repo_name, events)
    # TODO this is were we can tweak the weights of various types, repos and orgs
    events.length
  end

  def self.state_for_repo(repo_name, score)
    # TODO maybe make these thresholds tweakable
    return 'high' if score >= 5
    return 'low' if score >= 1
    return 'inactive' if score.zero?
  end

  def self.load_event_data(start_date, end_date)
    # might want to exclude certain event types
    # excludes PL folk and bots
    event_scope.select('events.created_at, actor, repository_full_name').created_after(start_date).created_before(end_date).all
  end

  def self.slice_events(events, window)
    # TODO handle window for values other than 1
    events.group_by{ |e| e.created_at.beginning_of_week }
  end

  def self.previously_active_repo_names(before_date)
    event_scope.created_before(before_date).pluck(:repository_full_name).uniq
  end

  def self.pl_orgs
    ['protocol', 'ipfs', 'ipfs-shipard', 'ipld', 'protoschool', 'libp2p',
      'ipfs-cluster', 'multiformats', 'ipfs-inactive', 'filecoin-project',
      'filecoin-shipyard', 'slate-engineering']
  end

  def self.event_scope
    # not star events
    # not PL employees/contractors
    # only repos with pl dependencies or search results or pl owned repos

    repository_ids = Repository.with_internal_deps.pluck(:id)
    repository_ids += Repository.with_search_results.pluck(:id)
    repository_ids -= Repository.internal.pluck(:id)
    repository_ids -= Repository.org(pl_orgs).pluck(:id)
    repository_ids.uniq!

    Event.not_core.where.not(event_type: ['WatchEvent', 'MemberEvent', 'PublicEvent']).where(repository_id: repository_ids)
  end
end