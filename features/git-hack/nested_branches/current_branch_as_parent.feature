Feature: Creating nested feature branches

  As a developer waiting for permission to ship a feature branch that contains changes needed for the next feature
  I want to be able to start working on the next feature while having access to the changes currently under review
  So that I am not slowed down by reviews and can keep working on my backlog as planned.


  Scenario: Creating a child branch of the current feature branch
    Given I have a feature branch named "feature"
    And Git Town knows that "feature" has the parent "main" and the parents "main"
    Given the following commit exists in my repository
      | BRANCH  | LOCATION | MESSAGE        | FILE NAME    |
      | main    | remote   | main_commit    | main_file    |
      | feature | local    | feature_commit | feature_file |
    And I am on the "feature" branch
    And I have an uncommitted file
    When I run `git hack child-feature feature`
    Then it runs the Git commands
      | BRANCH        | COMMAND                               |
      | feature       | git fetch --prune                     |
      |               | git stash -u                          |
      |               | git checkout main                     |
      | main          | git rebase origin/main                |
      |               | git checkout feature                  |
      | feature       | git merge --no-edit origin/feature    |
      |               | git merge --no-edit main              |
      |               | git push                              |
      |               | git checkout -b child-feature feature |
      | child-feature | git stash pop                         |
    And I end up on the "child-feature" branch
    And I still have my uncommitted file
    And the branch "child_feature" has not been pushed to the repository
    And I have the following commits
      | BRANCH        | LOCATION         | MESSAGE                          | FILE NAME    |
      | main          | local and remote | main_commit                      | main_file    |
      | child-feature | local            | feature_commit                   | feature_file |
      |               |                  | main_commit                      | main_file    |
      |               |                  | Merge branch 'main' into feature |              |
      | feature       | local and remote | feature_commit                   | feature_file |
      |               |                  | main_commit                      | main_file    |
      |               |                  | Merge branch 'main' into feature |              |
