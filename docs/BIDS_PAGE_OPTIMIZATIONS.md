# Bids Page Performance Optimizations

Requests for the bids page (e.g. `/auction/9/bids`) are slow due to several database query and Ecto inefficiencies. Below are the identified issues, prioritized by potential impact.

---

## 1. N+1 Query in `add_surplus_to_bids/2` — *High Impact*

**File:** `lib/ssauction/bids.ex` (lines 228–232)

`Players.get_value(bid.player, team)` fires **one DB query per bid** to fetch the player's value. With N active bids, this produces N extra queries.

**Fix:** Batch-load all values in a single query upfront:

```elixir
player_ids = Enum.map(bids, & &1.player.id)
values = Repo.all(from v in Value, where: v.player_id in ^player_ids and v.team_id == ^team.id)
value_map = Map.new(values, fn v -> {v.player_id, v.value} end)
```

Then look up from the map instead of hitting the DB per bid.

| Metric | Before | After |
|--------|--------|-------|
| DB queries for surplus | N | 1 |

---

## 2. Full Re-query on Every PubSub Event — *High Impact*

**File:** `lib/ssauction_web/live/auction_live/bids.ex` (lines 143–174)

Every `:new_nomination`, `:bid_expiration_update`, and `:bid_change` event calls `list_bids_with_expires_in_and_surplus/3`, which re-runs the full query pipeline (the `list_bids` query + N+1 value lookups + in-memory sort). During active bidding, these events fire frequently and hammer the DB.

**Fix options:**

- **Debounce/throttle:** Use `Process.send_after` so rapid-fire events coalesce into a single re-query.
- **Incremental updates:** For `:bid_change`, pass the changed bid in the broadcast message and update only that bid in `@bids` in-memory, rather than re-querying everything.

---

## 3. In-Memory Sorting Instead of DB-Level `ORDER BY` — *Medium Impact*

**File:** `lib/ssauction/bids.ex` (line 234)

`list_bids/1` fetches bids ordered by `expires_at`, then `sort_bids/2` re-sorts the entire list in Elixir. For columns that map directly to DB fields, the sort should happen in SQL.

**Fix:** Push sort clauses into the Ecto query's `order_by` for DB-native columns (`bid_amount`, `team.name`, `player.name`, `player.position`, `player.ssnum`, `expires_at`). Only fall back to in-memory sort for computed fields like `seconds_until_bid_expires` and `surplus`.

---

## 4. `user_in_team?/2` Preloads All Team Users on Every Call — *Medium Impact*

**File:** `lib/ssauction/teams.ex` (lines 154–156)

`user_in_team?/2` does `Repo.preload(team, [:users])` then scans the list. This is called in the template for **every row** of the bids table (via `current_user_in_team?(bid.team, @current_user)`).

**Fix:** Replace with a targeted `exists?` query:

```elixir
def user_in_team?(%Team{} = team, %User{} = user) do
  Repo.exists?(from ut in "teams_users",
    where: ut.team_id == ^team.id and ut.user_id == ^user.id)
end
```

Or better yet, precompute the set of team IDs the current user belongs to once in `handle_params` and pass it as an assign:

```elixir
user_team_ids = Teams.get_team_ids_for_user(current_user)
|> assign(:user_team_ids, user_team_ids)
```

Then in the template: `if bid.team_id in @user_team_ids`.

---

## 5. `user_in_auction?/2` Deeply Preloads auction→teams→users — *Medium Impact*

**File:** `lib/ssauction/auctions.ex` (lines 523–525)

`get_auction_user_ids/1` preloads the auction's teams, then each team's users, building a flat list. This is called per-row via `current_user_in_auction?(@auction, @current_user)` in the template.

**Fix:** Compute this once in `handle_params` and store it as a boolean assign (`@current_user_in_auction`), or use a single JOIN query:

```elixir
Repo.exists?(from t in Team,
  join: u in assoc(t, :users),
  where: t.auction_id == ^auction.id and u.id == ^user.id)
```

---

## 6. `expires_in` Computed in Elixir Instead of SQL — *Low-Medium Impact*

**File:** `lib/ssauction/bids.ex`

`seconds_until_bid_expires/2` is computed per bid in Elixir. This could be a SQL expression in the original query, reducing post-processing.

**Fix:** Use a `select_merge` with a SQL fragment:

```elixir
select_merge: %{
  seconds_until_bid_expires: fragment("EXTRACT(EPOCH FROM ? - NOW())", b.expires_at)
}
```

---

## 7. Missing Database Indexes — *Low Impact (verify first)*

Ensure indexes exist on:

- `bids.auction_id`
- `bids.team_id`
- `values.player_id` + `values.team_id` (composite)
- `bids.expires_at`

Check with `mix ecto.migrations` or inspect the schema directly.

---

## Summary

| Priority | Issue | Queries Saved |
|----------|-------|---------------|
| 1 | N+1 in `add_surplus_to_bids` | N → 1 |
| 2 | Full re-query on every PubSub event | Eliminates redundant full reloads |
| 3 | In-memory sort vs DB `ORDER BY` | Reduces data shuffling |
| 4 | `user_in_team?` preload per row | N preloads → 0 (precompute) |
| 5 | `user_in_auction?` deep preload per row | N deep preloads → 0 (precompute) |
| 6 | `expires_in` in Elixir vs SQL | Minor CPU/simplification |
| 7 | DB indexes | Depends on current state |
