extends Node

signal draw_card # card, hand, deck
signal discard_card # card, hand, discard

signal take_damage # new_hp, old_hp, max_hp
signal heal_damage # new_hp, old_hp, max_hp
signal died

signal momentum_inc # old_momentum, new_momentum
signal momentum_dec # old_momentum, new_momentum
signal combo_activate

var ID = 'CHARACTER_'

var HEALTH     = 0
var HEALTH_MAX = 0
var MOMENTUM   = 0
var DRAW_SIZE  = 4

var DECK      = []
var HAND      = []
var DISCARD   = []
# idx [1:4] correspond to momentum levels 1-4 ; idx 0 unused
var SIGNATURE = []

var SPRITE = null

func _init( data, rivers, minions ):
  slurp_data( data )
  add_child( rivers )
  rivers.name = "Rivers"
  # TODO add_child( minions )

func slurp_data( data ):
  var stats = data.stats
  var cards = data.cards

  ID += data.id

  HEALTH = stats.health
  HEALTH_MAX = stats.health_max
  DRAW_SIZE = stats.draw_size

  DECK = cards.deck
  SIGNATURE = cards.signature

  SPRITE = data.sprite

# =============== #
# SIGNAL HANDLERS #
# =============== #

func _on_turn_start( battle ):
  draw_hand()

func _on_turn_end( battle ):
  clear_hand()

# ======= #
# ACTIONS #
# ======= #

func draw_hand():
  print( ID, " // drawing new hand of size ", DRAW_SIZE )
  # TODO make sure there are cards to draw from the deck
  # to_draw = min( DRAW_SIZE, DECK.size() )
  for i in range( DRAW_SIZE ):
    print( ID, " // drawing card ", i )
    draw_card()

func draw_card():
  if DECK.empty() and not DISCARD.empty():
    print( ID, " // reshuffling discard into deck" )
    DECK = DISCARD
    DISCARD.clear()
    DECK.shuffle()

  var card = DECK.draw()
  HAND.push_back( card )
  print( ID, " // drew card ", card )
  emit_signal( 'draw_card', card, HAND, DECK )

func clear_hand():
  print( ID, " // clearing hand" )
  for c in HAND:
    discard_card( c )

func discard_card( card ):
  if not HAND.empty() and HAND.has( card ):
    DISCARD.push_back( card )
    HAND.erase( card )
    print( ID, " // discarded card ", card )
    emit_signal( 'discard_card', card, HAND, DISCARD )

func play_card( card, river ):
  print( ID, ' // ', 'playing card ', card, ' into river ', river )

  # TODO remove card from hand

  set_momentum( card.level )

func take_damage( amt ):
  HEALTH -= amt
  emit_signal( 'take_damage', HEALTH, HEALTH + amt, HEALTH_MAX )
  if HEALTH <= 0:
    emit_signal( 'died' )

func heal_damage( amt ):
  var old_hp = HEALTH
  HEALTH = min( HEALTH + amt, HEALTH_MAX )
  emit_signal( 'heal_damage', HEALTH, old_hp, HEALTH_MAX )

func set_momentum( lvl ):
  if lvl < MOMENTUM:
    emit_signal( 'momentum_dec', MOMENTUM, lvl )
    # signature_check()
  elif lvl > MOMENTUM:
    emit_signal( 'momentum_inc', MOMENTUM, lvl )

  MOMENTUM = lvl
  print( ID, ' // ', 'set momentum to ', lvl, ' from ', MOMENTUM )

# ======= #
# HELPERS #
# ======= #

func get_sprite():
  return SPRITE
