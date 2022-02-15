# SSAuction-Live

## TODO:

* create create auction page
* create nomination queue page with nomination modal
* create admin master page with links to other admin pages, link to it in footer if user is "super"
* add sort_name column to all_players and players tables
* consider other info to add to players table: range, platoon splits, link to Fangraphs, etc.
* display player page (with breadcrumbs) when clicking on player in auto-nomination queue page
* don't link to bids page from auction and team pages if there are zero open bids
* Teams Table on auction page: hide Time Nominations Expire and New Nominations Open At columns if there are no unused nominations
* Auto-Nomination Queue page: show Nominations Per Team
* Auto-Nomination Queue page: highlight top N players where N = Nominations Per Team
* allow teams of the same name, as long as they're not in the same auction
* figure out how to dedupe team_live/bids.html.heex and auction_live/bids.html.heex
