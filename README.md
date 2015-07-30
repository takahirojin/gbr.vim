# gbr.vim

Show git branch list

## Usage:

* Run `:Gbr` to show your local branch list.
* Press `Enter` to switch branch which you choose.
* Press `c` to create a new branch.
* Press `cc` to create and switch a new branch.
* Press `C` to create and switch a new branch from refs/heads/branch-name
* Press `m` to rename a branch. as same as "-m" options
* Press `d` to delete a branch. as same as "-d" options
* Press `D` to delete a branch. as same as "-D" options
* Press `q` to close branch list.

* Run `:GbrTruncateBranch` to delete branch exclude current branch

## Tips:

* display current branch on top of the list

        let g:gbr_current_branch_top = 1

* set maximum window height

        let g:gbr_window_height = 20

* set exclude branches when using GbrTruncateBranch command

        let g:gbr_exclusion_branch = ['foo', 'bar']

