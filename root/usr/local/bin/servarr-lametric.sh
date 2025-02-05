#!/bin/sh
if [ -z "$LAMETRIC_API" ] || [ -z "$LAMETRIC_IP" ]; then
	>&2 echo "Error: 'LAMETRIC_API' and/or 'LAMETRIC_IP' are unset!"
	exit 1
fi

app=$(printenv | sed -n 's/_eventtype *=.*$//p')
case "$app" in
	'sonarr')
		icon='3345'
		event_type=$sonarr_eventtype
		season_number="S${sonarr_release_seasonnumber:-$sonarr_episodefile_seasonnumber}"
		episode_numbers="E${sonarr_release_episodenumbers:-$sonarr_episodefile_episodenumbers}"
		target="$media_title ${season_number}${episode_numbers}"
		health_issue=$sonarr_health_issue_message
		;;
	'radarr')
		icon='65972'
		event_type=$radarr_eventtype
		target="$radarr_movie_title \($radarr_movie_year\)"
		health_issue=$radarr_health_issue_message
		;;
	*)
		>&2 echo 'Error: Script must be run from either Sonarr or Radarr'
		exit 1
		;;
esac

sound='letter_email'
case "$event_type" in
	'Grab')
		text="Grabbed $target"
		;;
	'Download')
		if [ "${sonarr_isupgrade:-$radarr_isupgrade}" = 'True' ]; then
			text="Upgraded ${target}"
		else
			text="Imported ${target}"
		fi
		;;
	'HealthIssue')
		text="$health_issue"
		sound='negative3'
	;;
	'ManualInteractionRequired')
		text="Manual interaction required for $target"
		sound='negative3'
	;;
	'Test')
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