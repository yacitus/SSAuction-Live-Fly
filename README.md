# SSAuction-Live

## TODO:

* fix log_in page (either by getting tailwindcss/nesting working or changing the templates)
* create upload players CSV page (to add to all_players) table
* create create auction page
* add sort_name column to all_players and players tables
* consider other info to add to players table: range, platoon splits, link to Fangraphs, etc.
* display player page (with breadcrumbs) when clicking on player in auto-nomination queue page
* don't link to bids page from auction and team pages if there are zero open bids
* Teams Table on auction page: hide Time Nominations Expire and New Nominations Open At columns if there are no unused nominations
* Auto-Nomination Queue page: show Nominations Per Team
* Auto-Nomination Queue page: highlight top N players where N = Nominations Per Team
* allow teams of the same name, as long as they're not in the same auction
* figure out how to dedupe team_live/bids.html.heex and auction_live/bids.html.heex
