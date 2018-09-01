extends Node

signal turn_start # Battle
signal turn_end # Battle
signal game_over # winner

signal card_played # who, card, river
signal card_activated # who, card, river
signal card_removed # who, card, river

var CUR_MOMENTUM = 0

# we need to be able to dynamically load different battle scenarios

func _init():
  pass

func _ready():
  # TEMP
  _setup( {
    'enemies': {
      'root': preload( "res://characters/enemies/skeleton.gd" ),
      'minions': { 'a' : null, 'b' : null, 'c' : null, 'd' : null }
    }
  } )

func _setup( params ):
  _setup_battle( params )
  $BattleUI.setup_ui()
  _connect_signals()

  _start_turn()

func add_child( child, name=null ):
  .add_child( child )
  if name:
    child.name = name

func _setup_battle( params ):
  var _rivers_ = preload( "res://battles/rivers.gd" )

  # BOARD[HERO].root    = preload( "res://characters/heroes/hero.gd" ).new()
  # BOARD[HERO].rivers  = _rivers_.new( HERO )
  # BOARD[HERO].minions = player_data.get_player_battle_data().minions
  var hero = preload( "res://characters/heroes/hero.gd" ).new(
    _rivers_.new( battlemaster.HERO ),
    null # TODO minions
  )
  add_child( hero, battlemaster.hero_id_to_str( battlemaster.HERO ) )

  # BOARD[CPU].root    = params.enemies.root
  # BOARD[CPU].rivers  = _rivers_.new( CPU )
  # BOARD[CPU].minions = params.enemies.minions
  var opponent = params.enemies.root.new(
    _rivers_.new( battlemaster.CPU ),
    null # TODO minions
  )
  add_child( opponent, battlemaster.hero_id_to_str( battlemaster.CPU ) )

func _connect_signals():
  # connect signals to/from hero
  var hero = get_fighter( battlemaster.HERO )
  connect( 'turn_start', hero, '_on_turn_start' )
  connect( 'turn_end',   hero, '_on_turn_end' )
  # connect signals to/from enemy
  # var enemy = get_fighter( CPU )
  # connect( 'turn_start', enemy, '_on_turn_start' )
  # connect( 'turn_end',   enemy, '_on_turn_end' )

# == PRIVATE CORE == #

func _start_turn():
  # this needs to be before the turn start signal emits
  # in order to guarantee the player has complete
  # information at the start of the turn timer
  get_fighter( battlemaster.CPU ).decide_next_move( self )
  emit_signal( 'turn_start', self )

func _end_turn():
  var result = _resolve_all_moves()
  if result == null:
    emit_signal( 'turn_end', self )
  else:
    emit_signal( 'game_over', result )

func _resolve_all_moves():
  # iterate up the rivers
  # for each momentum M in 1..4
  #  resolve momentum M card for hero
  #  resolve momentum M card for enemy
  var move = null

  for m in range( CUR_MOMENTUM ):
    # momentum methods are 1-indexed, and m will be reset at each iteration
    m += 1

    move = get_move_at_momentum( battlemaster.HERO, m )
    if move:
      # TEMP actually think though how this logics out
      move.card.activate( self, move.river )

      # TODO check for mini-combo satisfaction
      # for combo in player.combos:
      #   if combo.satisfied()
      #     combo.activate()

      # activate signature if final hit
      if m == 4:
        # TODO do signature shit
        pass

    move = get_move_at_momentum( battlemaster.CPU, m )
    if move:
      # TEMP actually think though how this logics out
      move.card.activate( self, move.river )

# == FIGHTER MOVES == #

func play_card( who, card, river ):
  var _name = 'player' if who == battlemaster.HERO else 'enemy'
  print( 'battle.gd // ', _name, ' is playing card ', card, ' into river ', river )

  var rivers = get_rivers( who )

  if rivers.validate_play( card, river ):
    rivers.place_card( card, river )
  else:
    print( "battle.gd // that was not a valid move" )


  emit_signal( 'card_played', who, card, river )

# TODO
func pass_turn():
  pass # lol

# TODO
func swap_rivers():
  pass

func mulligan():
  var hero = get_fighter( battlemaster.HERO )
  hero.clear_hand()
  hero.draw_hand()
  # TODO flag the mulligan for this turn

# == HELPERS == #

# who will be targeted by an attack in a river vs the enemy or hero
func target_in_river( vs, river ):
  if !has_minions( vs ):
    var minion = get_minion_in_river( vs, river )

    if minion:
      return minion

    match( river ):
      'a':
        river = 'b'
      'b':
        river = 'a' if get_minion_in_river( vs, 'a' ) else 'c'
      'c':
        river = 'd' if get_minion_in_river( vs, 'd' ) else 'b'
      'd':
        river = 'c'

    minion = get_minion_in_river( vs, river )

    if minion:
      return minion

  return get_fighter( vs )

# TODO
func available_moves( who ):
  # return the river steps that can have cards played in them
  return null

func can_place_card( who, card, river ):
  # check if momentum is within limits for that fighter
  var cur_mom = get_current_momentum( who )
  if card.get_power() > cur_mom + 1:
    return false

  # check if the fighter can't play the card
  # if !get_fighter( who ).can_play_card( card, river ):
  #   return false

  return true

# TODO
func test_move_outcome( who, card, river ):
  # copy board state, make test move, and calculate the resulting board state
  return null

# == GETTERS == #

func get_fighter( who ):
  return get_node( battlemaster.hero_id_to_str( who ) )

func get_active_moves( who ):
  return get_rivers( who ).get_active_moves()

func get_current_momentum( who ):
  return get_rivers( who ).get_active_momentum()

func get_rivers( who ):
  return get_fighter( who ).get_node( "Rivers" )

# func get_minions( who ):
#   return BOARD[who].minions

func has_minions( who ):
  var minions = get_minions( who )

  for m in minions.values:
    if m != null:
      return true

  return false

# ==== GET by river

func get_minion_in_river( who, river ):
  return get_minions( who )[river]

# ==== GET by momentum

# the 'level' is 1-indexed
func get_move_at_momentum( who, level ):
  get_rivers( who ).get_move_at_momentum( level )

# the 'level' is 1-indexed
func get_active_river_at_momentum( who, level ):
  get_rivers( who ).get_active_river_at_momentum( level )

# the 'level' is 1-indexed
func get_card_at_momentum( who, level ):
  get_rivers( who ).get_card_at_momentum( level )
