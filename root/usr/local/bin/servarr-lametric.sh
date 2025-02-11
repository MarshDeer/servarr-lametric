#!/bin/sh
if [ -z "$LAMETRIC_API" ] || [ -z "$LAMETRIC_IP" ]; then
	>&2 echo "Error: 'LAMETRIC_API' and/or 'LAMETRIC_IP' are unset!"
	exit 1
fi

app=$(printenv | sed -n 's/_eventtype *=.*$//p')
case "$app" in
	'sonarr')
		icon='66050'
		event_type=$sonarr_eventtype
		season_number="S${sonarr_release_seasonnumber:-$sonarr_episodefile_seasonnumber}"
		episode_numbers="E${sonarr_release_episodenumbers:-$sonarr_episodefile_episodenumbers}"
		target="$sonarr_series_title ${season_number}${episode_numbers}"
		health_issue=$sonarr_health_issue_message
		;;
	'radarr')
		icon='65972'
		event_type=$radarr_eventtype
		target="$radarr_movie_title \($radarr_movie_year\)"
		health_issue=$radarr_health_issue_message
		;;
	'readarr')
		icon='66049'
		event_type=$readarr_eventtype
		book_title=${readarr_release_booktitles:-$readarr_book_title}
		target="$readarr_author_name - $book_title"
		health_issue="$readarr_health_issue_message"
		;;
	'lidarr')
		icon='66048'
		event_type=$lidarr_eventtype
		album_title="${lidarr_release_albumtitles:-$lidarr_album_title}"
		target="$lidarr_artist_name - $album_title"
		health_issue=$lidarr_health_issue_message
		;;
	'prowlarr')
		icon='66052'
		event_type=$prowlarr_eventtype
		health_issue=$prowlarr_health_issue_message
		;;
	*)
		>&2 echo 'Error: Script must be run from a compatible app'
		exit 1
		;;
esac

sound='letter_email'
case "$event_type" in
	Grab)
		text="Grabbed $target"
		;;
	*Download)
		if [ "${sonarr_isupgrade:-$radarr_isupgrade}" = 'True' ]; then
			text="Upgraded ${target}"
		else
			text="Imported ${target}"
		fi
		;;
	HealthIssue)
		text="$health_issue"
		sound='negative3'
	;;
	ManualInteractionRequired)
		text="Manual interaction required for $target"
		sound='negative3'
	;;
	Test)
		text="Test successful!"
	;;
	*)
		>&2 echo "Error: Unsupported event type"
	;;
esac

curl \
	--silent \
	--request POST \
	--user "dev:${LAMETRIC_API}" \
	--header "Content-Type: application/json" \
	--data "{
		\"icon_type\": \"none\",
		\"model\": {
			\"frames\": [
				{
					\"icon\":\"$icon\",
					\"text\":\"$text\"
				}
			],
			\"sound\": {
				\"category\":\"notifications\",
				\"id\":\"$sound\",
				\"repeat\":1
			}
		}
	}" \
	http://"$LAMETRIC_IP":8080/api/v2/device/notifications