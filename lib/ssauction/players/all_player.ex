defmodule SSAuction.Players.AllPlayer do
  use Ecto.Schema
  import Ecto.Changeset

  schema "all_players" do
    field :year_range, :string    
    field :ssnum, :integer
    field :name, :string
    field :position, :string
  end

  def changeset(player, params \\ %{}) do
    required_fields = [:year_range, :ssnum, :name, :position]

    player
    |> cast(params, required_fields)
    |> validate_required(required_fields)
    # TODO - :position should be split by / and each slice confirmed to be in the list below
    # |> validate_inclusion(:position, ["SP", "RP", "C", "1B", "2B", "3B", "SS", "OF", "DH"])
    |> validate_year_range()
    # |> validate_unique_year_range_and_ssnum() # don't need this because expect insert!(on_conflict: :nothing)
  end

  def validate_year_range(changeset) do
    case changeset.valid? do
      true ->
        year_range = get_field(changeset, :year_range)
        case String.length(year_range) do
          7 ->
            case parse_year_range(year_range) do
              %{"year" => _year, "league" => _league} ->
                  changeset
              _ ->
                add_error(changeset, :year_range, "can't find start and end year")
            end
          _ ->
            add_error(changeset, :year_range, "must be 7 characters")
        end

      _ ->
        changeset
    end
  end

  def parse_year_range(year_range) do
    Regex.named_captures(~r/(?<year>\d{4})-(?<league>[A-Z]{2})/, year_range)
  end

  # defp validate_unique_year_range_and_ssnum(changeset) do
  #   case changeset.valid? do
  #     true ->
  #       year_range = get_field(changeset, :year_range)
  #       ssnum = get_field(changeset, :ssnum)
  #       query = from player in SSAuction.Players.Player,
  #               where: player.year_range == ^year_range and player.ssnum == ^ssnum
  #       case SSAuction.Repo.all(query) do
  #         [] ->
  #           changeset
  #         _ ->
  #           add_error(changeset, :year_range, "and ssnum not unique", ssnum: ssnum)
  #       end

  #     _ ->
  #       changeset
  #   end
  # end
end
