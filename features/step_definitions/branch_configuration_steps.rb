Given(/^Git Town is aware of this branch hierarchy$/) do |table|
  table.hashes.each do |row|
    set_parent_branch branch: row['BRANCH'], parent: row['PARENT']
  end
end


Given(/^Git Town has no branch hierarchy information for "(.*?)"$/) do |branch_names|
  Kappamaki.from_sentence(branch_names).each do |branch_name|
    run_shell_command "git config --unset git-town.branches.parent.#{branch_name}"
    run_shell_command "git config --unset git-town.branches.parents.#{branch_name}"
  end
end


Then(/^Git Town is now aware of this branch hierarchy$/) do |table|
  table.diff! configured_branch_hierarchy_information.table
end
