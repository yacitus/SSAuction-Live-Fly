# SSAuction-Live

## TODO:

* add admin page to change a single team's number of unused nominations
* add My Value column to Players Available to Nominate table on nomination queue page
* player not removed from nomination queue table (unless page refreshed) after removed if only player in table
* intemittently logging when hidden high bid is changed?
* allow a team to be "done" with the auction and stop giving them nominations (but stop allowing them to bid)
* make team bids tables sortable
* change background hover color of Bid and Edit "button" table cells in bids tables to make them stand-out (and use a subtler background hover color for the bid amounts for going to bid logs)
* allow setting player values by uploading a CSV of ssnums and values
* display nomination and bid errors in modal, not background
* add sort_name column to all_players and players tables
* consider other info to add to players table: range, platoon splits, link to Fangraphs, etc.
* display player page (with breadcrumbs) when clicking on player in auto-nomination queue page
* Auto-Nomination Queue page: show Nominations Per Team
* Auto-Nomination Queue page: highlight top N players where N = Nominations Per Team
* don't allow adding a team to an auction that already has a team with that name
* don't allow renaming a team in an auction that already has a team with that name
* refactor common code out of reroster_cut_player & roster_player_and_delete_bid in lib/ssauction/bids.ex
* dedupe sort_link, toggle_sort_order, and emoji functions
* figure out how to dedupe team_live/bids.html.heex and auction_live/bids.html.heex
* make Teams table sortable on /admin/auction/:id/create_team page
* link to user's Slack profile in Owners table on Team Info page
* fix bug in /admin/team/:id/add_user page where added username is not removed from selection list after adding
* fix bug (same as above) in /admin/confirm_user page where confirmed user is not removed from selection list after confirming
