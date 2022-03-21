# SSAuction-Live

## TODO:

* make sure bidding under or equal to the hidden max bid results in a bid equal to the highest bid, not greater than
* may be a bug where last player in nomination queue is not removed after nominating
* show dollars remaining for bids (including hidden max bids) in team info page if the signed-in user is a member of the team, not-including hidden max bids otherwise
* click on players in auction and team bids tables to go to bid log
* make auction and team bids tables sortable
* color-code Bid and Edit "buttons" in bids tables to make them stand-out
* display nomination and bid errors in modal, not background
* create admin master page with links to other admin pages, link to it in footer if user is "super"
* add sort_name column to all_players and players tables
* consider other info to add to players table: range, platoon splits, link to Fangraphs, etc.
* display player page (with breadcrumbs) when clicking on player in auto-nomination queue page
* don't link to bids page from auction and team pages if there are zero open bids
* Teams Table on auction page: hide Time Nominations Expire and New Nominations Open At columns if there are no unused nominations
* Auto-Nomination Queue page: show Nominations Per Team
* Auto-Nomination Queue page: highlight top N players where N = Nominations Per Team
* don't allow adding a team to an auction that already has a team with that name
* don't allow renaming a team in an auction that already has a team with that name
* dedupe sort_link, toggle_sort_order, and emoji functions
* figure out how to dedupe team_live/bids.html.heex and auction_live/bids.html.heex
* make Teams table sortable on /admin/auction/:id/create_team page
* link to user's Slack profile in Owners table on Team Info page
* fix bug in /admin/team/:id/add_user page where added username is not removed from selection list after adding
* fix bug (same as above) in /admin/confirm_user page where confirmed user is not removed from selection list after confirming
