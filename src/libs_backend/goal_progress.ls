{memoizeSingleAsync} = require 'libs_common/memoize'

{
  gexport
  gexport_module
} = require 'libs_common/gexport'

{
  as_array
} = require 'libs_common/collection_utils'

{cfy} = require 'cfy'

measurement_functions = require 'goals/progress_measurement'
measurement_functions_generated = require 'goals/progress_measurement_generated'

#temp!!
{
  get_visits_to_domain_days_before_today
} = require 'libs_common/time_spent_utils'

export get_progress_measurement_functions = ->>
  output = {}
  goals = await goal_utils.get_goals()
  for goal_name,goal_info of goals
    if goal_info.measurement?
      measurement_function = measurement_functions[goal_info.measurement]
      if measurement_function?
        output[goal_name] = measurement_function(goal_info)
        continue
    measurement_function = measurement_functions_generated[goal_name]
    if measurement_function?
      output[goal_name] = measurement_function(goal_info)
      continue
    console.log "no measurement found for goal #{goal_name}"
  return output

export get_progress_measurement_function_for_goal_name = (goal_name) ->>
  progress_measurement_functions = await get_progress_measurement_functions()
  return progress_measurement_functions[goal_name]

export get_progress_on_goal_today = (goal_name) ->>
  await get_progress_on_goal_days_before_today goal_name, 0

export get_progress_on_goal_this_week = (goal_name) ->>
  results = []
  for days_before_today from 0 to 6
    progress_info = await get_progress_on_goal_days_before_today goal_name, days_before_today
    results.push progress_info
  return results

export get_progress_on_enabled_goals_today = ->>
  await get_progress_on_enabled_goals_days_before_today 0

export get_progress_on_goal_days_before_today = (goal_name, days_before_today) ->>
  goal_measurement_function = await get_progress_measurement_function_for_goal_name goal_name
  if not goal_measurement_function?
    console.log 'no goal_measurement_function found for goal'
    console.log goal_name
    return
  await goal_measurement_function days_before_today

export get_num_goals_met_today = ->>
  await get_num_goals_met_days_before_today 0

export get_num_goals_met_yesterday = ->>
  await get_num_goals_met_days_before_today 1

export get_num_goals_met_days_before_today = (days_before_today) ->>
  enabled_goals = await goal_utils.get_enabled_goals()
  goal_targets = await goal_utils.get_all_goal_targets()
  num_goals_met = 0
  for goal_name in as_array(enabled_goals)
    progress_info = await get_progress_on_goal_days_before_today goal_name, days_before_today
    goal_target = goal_targets[goal_name]
    if progress_info.progress < goal_target
      num_goals_met += 1
  return num_goals_met

export get_num_goals_met_this_week = ->>
  enabled_goals = await goal_utils.get_enabled_goals()
  goal_targets = await goal_utils.get_all_goal_targets()
  days_before_today_to_num_goals_met = [0]*7
  for days_before_today from 0 to 6
    num_goals_met = 0
    for goal_name in as_array(enabled_goals)
      progress_info = await get_progress_on_goal_days_before_today goal_name, days_before_today
      goal_target = goal_targets[goal_name]
      if progress_info.progress < goal_target
        num_goals_met += 1
    days_before_today_to_num_goals_met[days_before_today] = num_goals_met
  return days_before_today_to_num_goals_met

/**
 * Gets the streak (days in a row completed) for each enabled goal
 * @return {Promise.<Object.<string, int>>} Object mapping goal names to streaks.
 */
export get_positive_streaks = ->>
  enabled_goals = await goal_utils.get_positive_enabled_goals()
  goal_targets = await goal_utils.get_all_goal_targets()
  output = {}
  for goal_name in as_array(enabled_goals)
    streak = 0
    streak_continuing = true
    while streak_continuing
      progress_info = await get_progress_on_goal_days_before_today goal_name, streak
      goal_target = goal_targets[goal_name]
      if progress_info.progress > goal_target
        streak += 1
      else
        streak_continuing = false
    output[goal_name] = streak
  return output

export get_streak = (goal_name, goal_info) ->>
  target = await goal_utils.get_goal_target(goal_name)
  streak = 0
  streak_continuing = true
  console.log await get_visits_to_domain_days_before_today goal_info.domain, 0
  while streak_continuing
    progress_info = await get_progress_on_goal_days_before_today goal_name, streak
    if goal_info.is_positive == (progress_info.progress > target)
      streak += 1
    else
      streak_continuing = false
  return streak

export get_progress_on_enabled_goals_days_before_today = (days_before_today) ->>
  enabled_goals = await goal_utils.get_enabled_goals()
  enabled_goals_list = as_array enabled_goals
  output = {}
  for goal_name in enabled_goals_list
    progress_info = await get_progress_on_goal_days_before_today goal_name, days_before_today
    output[goal_name] = progress_info
  return output

/**
 * Gets the goal progress info on each enabled goal this week.
 * @return {Promise.<Object.<string, Array.<GoalProgressInfo>>>} Object mapping goal names to an array of goal progress info objects, one for each of the past 7 days (index 0=today, 1=yesterday, etc)
 */
export get_progress_on_enabled_goals_this_week = ->>
  enabled_goals = await goal_utils.get_enabled_goals()
  enabled_goals_list = as_array enabled_goals
  output = {}
  for goal_name in enabled_goals_list
    progress_this_week = await get_progress_on_goal_this_week goal_name
    output[goal_name] = progress_this_week
  return output

intervention_manager = require 'libs_backend/intervention_manager'
goal_utils = require 'libs_backend/goal_utils'

gexport_module 'goal_progress', -> eval(it)
