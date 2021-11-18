# ------------------------------------------------------------------
# [Sam Govier] FRTechDebtToNotion.py
#           This script takes information about technical debt
#           from the log applet mysql database,
#           exports it to trello, and marks it as exported
# ------------------------------------------------------------------

import mysql.connector
import requests

mydb = mysql.connector.connect(
    host="example",
    user="root",
    password="xxx",
    database="example"
)


mycursor = mydb.cursor()

# toexport is the tab/line delimited list of mysql data pertaining to unresolved tech debt from the log applet
toexport = mycursor.execute("SELECT id,Name,Date_stamp,ServersList FROM tblgbcomments WHERE EndOfAction_ExportType=1 AND EndOfAction_DateTime < now()")

# split toexport by new line and then tabs
toexport = toexport.Split('\n')
for i in range(0,len(toexport)):
    toexport[i] = toexport[i].Split('\t')

# for each line, get id, user, date, servers info, and then post to Notion
for entry in toexport:
    id = entry[0]
    user = entry[1]
    date = entry[2]
    servers = entry[3]

    # post_data is the JSON
    post_data = """
    {
        "parent": { "database_id": "84beb6635635434088a7b716580763df" },
        "properties": {
            "Name": {
                "title": [
                    {
                        "text": {
                            "content": "LogApplet #{id} created by {user} about {servers}"
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
                                "content": "Creation Date: {date}\\nCreation User: {user}\\nRelevant Servers: {servers}\\nLogApplet ID: {id}"
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
                                "content": "Click here to read the body of the log applet",
                                "link": { "url": "https://portal.eodops.com/Dashboard_LogApp/index.php?logid={id}" }
                            }
                        }
                    ]
                }
            }
        ]
    }
    """

    # head is headers
    head = {
        "Authorization": "Bearer xxx",
        "Content-Type": "application/json",
        "Notion-Version": "2021-08-16"
    }
    requests.post("https://api.notion.com/v1/pages", headers=head, data=post_data)

# run an update against the mysql database to mark exported data to the tech debt board
mycursor.execute("UPDATE tblgbcomments SET EndOfAction_ExportType=-1 WHERE EndOfAction_ExportType=1 AND EndOfAction_DateTime < now()")

###

