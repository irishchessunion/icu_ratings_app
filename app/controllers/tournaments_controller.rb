class TournamentsController < ApplicationController
  def new
  end

  def create
    tournament = Tournament.new(
      name: params["name"],
      original_name: params["name"],
      start: params[:start_date],
      original_start: params[:start_date],
      finish: params[:end_date],
      original_finish: params[:end_date],
      rounds: params[:num_rounds],
      user: current_user)

    icu_player = IcuPlayer.find(params[:icu_id])
    player = Player.new(
      icu_id: icu_player.id,
      first_name: icu_player.first_name,
      last_name: icu_player.last_name,
      fed: icu_player.fed,
      title: icu_player.title,
      gender: icu_player.gender,
      icu_rating: icu_player.latest_rating,
      fide_id: icu_player.fide_id,
      fide_rating: icu_player.fide_rating,
      dob: icu_player.dob,
      tournament: tournament,
      num: 1,
      original_name: icu_player.name,
      original_fed: icu_player.fed,
      original_title: icu_player.title,
      original_gender: icu_player.gender,
      original_icu_id: icu_player.id,
      original_fide_id: icu_player.fide_id,
      original_icu_rating: icu_player.latest_rating,
      original_fide_rating: icu_player.fide_rating
    )

    player.save!

    (1..params[:num_rounds].to_i).each do |r|
      create_result(tournament, player, r)
    end

    redirect_to admin_tournament_path(tournament)

  end

  def create_result(tournament, player, round)

    original_last_name = params["r#{round}_last_name"]
    original_first_name = params["r#{round}_first_name"]
    original_name = "#{original_last_name}, #{original_first_name}"

    opponent = Player.new(
      first_name: params["r#{round}_first_name"],
      last_name: params["r#{round}_last_name"],
      fed: params["r#{round}_fed"],
      title: params["r#{round}_fide_title"].presence,
      fide_rating: params["r#{round}_fide_elo"],
      tournament: tournament,
      num: round + 1,
      original_name: original_name,
      original_fed: params["r#{round}_fed"],
      original_title: params["r#{round}_fide_title"].presence,
      original_fide_rating: params["r#{round}_fide_elo"]
    )

    opponent.save!

    result = Result.new(
      round: round,
      player: player,
      opponent: opponent,
      result: params["r#{round}_result"][0],
      colour: params["r#{round}_colour"][0],
      rateable: true,
    )

    result.save!

    opponent_result = Result.new(
      round: round,
      player: opponent,
      opponent: player,
      result: result.opposite_result,
      colour: result.opposite_colour,
      rateable: true,
    )

    opponent_result.save!
  end

  def index
    params[:admin] = false
    @tournaments = Tournament.search(params, tournaments_path)
    render :results if request.xhr?
  end

  def show
    respond_to do |format|
      format.html do
        @tournament = Tournament.includes(players: [:results]).find(params[:id])
        @rankable = @tournament.rankable
        @players = @tournament.ordered_players
        render "show"
      end
      format.js do
        @tournament = Tournament.find(params[:id])
        render "show_notes"
      end
    end
  end
end
