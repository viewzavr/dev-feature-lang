* In windows, use `setup.reg` to add "Open with VR-Cinema..." context menu to folders.
* Use `setupoff.reg` to remove that menu.

Technical note. We do not use `--yes` flag in command line because we have to support windows 7
and npx behaves wrong when that flag is specified.