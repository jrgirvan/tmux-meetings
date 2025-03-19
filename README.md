# Meetings plugin for tmux

Shows next meeting in the status line, data provided by [icalBuddy](https://hasseg.org/icalBuddy/)

![tmux-meetings](./assets/tmux-preview.png)

## Installation

### With Tmux Plugin Manager
Add the plugin in `.tmux.conf`:
```
set -g @plugin 'jrgirvan/tmux-meetings'
```
Press `prefix + I` to fetch the plugin and source it. Done.

### Manual
Clone the repo somewhere. Add `run-shell` in the end of `.tmux.conf`:

```
run-shell PATH_TO_REPO/meetings.tmux
```
NOTE: this line should be placed after `set-option -g status-right ...`.

Press `prefix + :` and type `source-file ~/.tmux.conf`. Done.

## Usage
Add `#{meetings}` somewhere in the right status line:
```
set-option -g status-right "#{meetings}"
```
then you will see your next meeting in the status line: ` 14:00 - 1:1 Manager`

## Customization
The plugin could be customized with:
* `set-option -g @tmux-meetings-calendars "your.email@addre.ss"` - Set up the email address to include, comma delimited

## License
tmux-meetings plugin is released under the [MIT License](https://opensource.org/licenses/MIT).
