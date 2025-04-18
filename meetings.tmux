#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/scripts/helpers.sh"

ALERT_IF_IN_NEXT_MINUTES=$(get_tmux_option "@tmux-meetings-alert-minutes" "15")
ALERT_POPUP_BEFORE_SECONDS=$(get_tmux_option "@tmux-meetings-popup-seconds" "10")
ICON_FREE=$(get_tmux_option "@tmux-meetings-icon-free" "󱁕 ")
ICON_MEETING=$(get_tmux_option "@tmux-meetings-icon-meeting" "󰤙")

CALENDARS=$(get_tmux_option "@tmux-meetings-calendars")
if [ -n "$CALENDARS" ]; then
    calendar_option="-ic $CALENDARS"
else
    calendar_option=""
fi

get_attendees() {
	attendees=$(
	icalBuddy \
		--includeEventProps "attendees" \
		--propertyOrder "datetime,title" \
		--noCalendarNames \
		--dateFormat "%A" \
		--includeOnlyEventsFromNowOn \
		--limitItems 1 \
		--excludeAllDayEvents \
		--separateByDate \
		--excludeEndDates \
		--bullet "" \
        $calendar_option \
        eventsToday)
}

parse_attendees() {
	attendees_array=()
	for line in $attendees; do
		attendees_array+=("$line")
	done
	number_of_attendees=$((${#attendees_array[@]}-3))
}

get_next_meeting() {
	next_meeting=$(icalBuddy \
        --includeEventProps "title,datetime" \
        --propertyOrder "datetime,title" \
        --noCalendarNames \
        --dateFormat "%A" \
        --includeOnlyEventsFromNowOn \
        --limitItems 1 \
        --excludeAllDayEvents \
        --separateByDate \
        --bullet "" \
        $calendar_option \
        eventsToday)
}

get_next_next_meeting() {
    end_time_nnm=$(echo "$end_time" | tr -d '[:space:]' | sed 's/AM/ AM/' | sed 's/PM/ PM/')
    end_time_nnm=$(date -j -f "%I:%M %p" "$end_time_nnm" +"%H:%M" 2>/dev/null)
	end_timestamp=$(date +"%Y-%m-%d ${end_time_nnm}:01 %z")
	tonight=$(date +"%Y-%m-%d 23:59:00 %z")
    next_meeting=$(icalBuddy \
		--includeEventProps "title,datetime" \
		--propertyOrder "datetime,title" \
		--noCalendarNames \
		--dateFormat "%A" \
		--limitItems 1 \
		--excludeAllDayEvents \
		--separateByDate \
		--bullet "" \
        $calendar_option \
		eventsFrom:"${end_timestamp}" to:"${tonight}")
}

parse_result() {
	array=()
	for line in $1; do
		array+=("$line")
	done
	time="${array[2]}"
	end_time="${array[4]}"
	title="${array[*]:5:30}"
}

calculate_times(){
	# Ensure the time string is in the correct format
	time=$(echo "$time" | tr -d '[:space:]' | sed 's/AM/ AM/' | sed 's/PM/ PM/')

	# Convert the time to 24-hour format
	formatted_time=$(date -j -f "%I:%M %p" "$time" +"%H:%M" 2>/dev/null)

	epoc_meeting=$(date -j -f "%H:%M:%S" "$formatted_time:00" +%s 2>/dev/null)
	epoc_now=$(date +%s)
	epoc_diff=$((epoc_meeting - epoc_now))
	minutes_till_meeting=$((epoc_diff/60))
}

display_popup() {
	tmux display-popup \
		-S "fg=#eba0ac" \
		-w50% \
		-h50% \
		-d '#{pane_current_path}' \
		-T meeting \
		icalBuddy \
			--propertyOrder "datetime,title" \
			--noCalendarNames \
			--formatOutput \
			--includeEventProps "title,datetime,notes,url,attendees" \
			--includeOnlyEventsFromNowOn \
			--limitItems 1 \
			--excludeAllDayEvents \
            $calendar_option \
			eventsToday
}

print_tmux_status() {
	if [[ $minutes_till_meeting -lt $ALERT_IF_IN_NEXT_MINUTES \
		&& $minutes_till_meeting -gt -60 ]]; then
		echo "$ICON_MEETING \
			$time $title ($minutes_till_meeting minutes)"
	else
		echo "$ICON_FREE"
	fi
	if [[ $epoc_diff -gt $ALERT_POPUP_BEFORE_SECONDS && epoc_diff -lt $ALERT_POPUP_BEFORE_SECONDS+10 ]]; then
		display_popup
	fi
}

main() {
    get_calendar
	get_attendees
	parse_attendees
	get_next_meeting
	parse_result "$next_meeting"
	calculate_times
	if [[ "$next_meeting" != "" && $number_of_attendees -lt 1 ]]; then
		get_next_next_meeting
		parse_result "$next_next_meeting"
		calculate_times
	fi
	print_tmux_status
	# echo "$minutes_till_meeting | $number_of_attendees"
}

main

