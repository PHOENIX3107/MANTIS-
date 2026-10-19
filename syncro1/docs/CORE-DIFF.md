# Core diff against pinned upstream

The comparison baseline is the signed upstream tag `release-2.28.4`, resolved
to commit `ceb74c8056753e0d4089af95bde794e47fa2ef53`.

Command executed:

```text
git diff --name-status release-2.28.4 -- account_update.php core/events_inc.php core/user_api.php core/commands/UserCreateCommand.php core/commands/UserUpdateCommand.php
M	account_update.php
M	core/commands/UserCreateCommand.php
M	core/commands/UserUpdateCommand.php
M	core/events_inc.php
M	core/user_api.php

git diff --numstat release-2.28.4 -- account_update.php core/events_inc.php core/user_api.php core/commands/UserCreateCommand.php core/commands/UserUpdateCommand.php
0	1	account_update.php
21	3	core/commands/UserCreateCommand.php
2	1	core/commands/UserUpdateCommand.php
2	0	core/events_inc.php
9	2	core/user_api.php
```

Reconciliation with `CUSTOMIZATIONS.md`: all five modified runtime core files
listed there are present, and no additional runtime core file is modified.
The temporary-password path is documented there as an additional intentional
change to `core/commands/UserCreateCommand.php` and `core/user_api.php`, with
the create-page files outside the runtime-core comparison.
The full repository diff also contains deployment, documentation, CI, test,
and repository-scaffolding files; those are outside the MantisBT core patch.
The plugin and `syncro1/` implementation are intentionally outside this core
comparison.
