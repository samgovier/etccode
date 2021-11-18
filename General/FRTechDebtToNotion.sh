#!/bin/bash
# ------------------------------------------------------------------
# [Sam Govier] FRTechDebtToNotion.sh
#           This script takes information about technical debt
#           from the log applet mysql database,
#           exports it to trello, and marks it as exported
# ------------------------------------------------------------------

# --generate_post_data outputs proper Notion JSON data--------------
generate_post_data()
{
  cat <<EOF
{
	"parent": { "database_id": "84beb6635635434088a7b716580763df" },
	"properties": {
		"Name": {
			"title": [
				{
					"text": {
						"content": "LogApplet #$id created by $user about $servers"
					}
				}
			]
		},
		"Status": {
			"select": {
				"name": "UnQualified"
			}
		}
	},
	"children": [
		{
			"object": "block",
			"type": "heading_2",
			"heading_2": {
				"text": [{ "type": "text", "text": { "content": "LogApplet Info" } }]
			}
		},
		{
			"object": "block",
			"type": "paragraph",
			"paragraph": {
				"text": [
					{
						"type": "text",
						"text": {
							"content": "Creation Date: $date\\nCreation User: $user\\nRelevant Servers: $servers\\nLogApplet ID: $id"
						}
					}
				]
			}
		},		{
			"object": "block",
			"type": "paragraph",
			"paragraph": {
				"text": [
					{
						"type": "text",
						"text": {
							"content": "Click here to read the body of the log applet"
						}
					}
				]
			}
		}
	]
}
EOF
}

# toexport is the tab/line delimited list of mysql data pertaining to unresolved tech debt from the log applet
toexport=$(mysql -h 127.0.0.1 -Bse "SELECT id,Name,Date_stamp,ServersList FROM tblgbcomments WHERE EndOfAction_ExportType=1 AND EndOfAction_DateTime < now()")

# IFS is Input Field Separators: here it is marked as newline so the sql data can be separated by line
IFS="
"

# deliniated is the sql export data as a line-deliniated array
deliniated="$toexport"

# for each line from the database, export to Notion
for line in $deliniated; do

    # for each line, take the tab-deliniated values as the id, user, date and servers values respectively
    id=$(echo "$line" | awk -F"\t" '{print $1}')
    user=$(echo "$line" | awk -F"\t" '{print $2}')
    date=$(echo "$line" | awk -F"\t" '{print $3}')
    servers=$(echo "$line" | awk -F"\t" '{print $4}')

    # curl POST to Notion with the tech debt information
    curl 'https://api.notion.com/v1/pages' \
      -H "Content-Type: application/json" \
      -H "Notion-Version: 2021-08-16" \
      --data "$(generate_post_data)"
done

# run an update against the mysql database to mark exported data to the tech debt board
mysql -h 127.0.0.1 -Bse "UPDATE tblgbcomments SET EndOfAction_ExportType=-1 WHERE EndOfAction_ExportType=1 AND EndOfAction_DateTime < now()"