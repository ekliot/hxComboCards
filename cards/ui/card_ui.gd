extends TextureRect

var _POINTER_ = preload( "res://cards/ui/card_pointer.gd" )

var CARD = null

var pointer = null

var hovered = false
var bigger = false
var pointing = false

# == OVERRIDES == #

func _init():
  set_custom_minimum_size( texture.get_size() )

func _input( ev ):
  if ev is InputEventMouseMotion and player_data.can_hold( CARD ):
    hovered = _is_mouse_inside()
    if hovered:
      grow()
    elif !pointing:
      shrink()

  # Mouse in viewport coordinates
  if ev is InputEventMouseButton:
    # TODO filtering based on which button
    if hovered:
      if !pointing and ev.is_pressed():
        # make a new line pointer
        pick_up()
    else:
      if pointing and !ev.is_pressed():
        drop_me()

func _is_mouse_inside():
  var mpos = get_viewport().get_mouse_position()
  var mrect = Rect2( mpos, Vector2( 1, 1 ) )
  return get_global_rect().encloses( mrect )

# == ACTIONS == #

func build( card ):
  CARD = card
  # TODO actually overlay all the elements with data from the card
  return

func pick_up():
  player_data.pick_up_card( CARD )
  pointer = point()

func point():
  var ptr = _POINTER_.new( self, get_pointer_origin() )
  add_child( ptr )
  ptr.point_to( get_viewport().get_mouse_position() )
  pointing = true

  # connect pointer to valid river nodes
  battlemaster.get_rivers_ui( 'Hero' ).connect_to_card_pointer( CARD, ptr )

  return ptr

func grow():
  if !bigger:
    rect_size = rect_size * 2
    # print( rect_size )
    # print( margin_left, ' ', margin_top, ' ', margin_right, ' ', margin_bottom )
    bigger = true

func shrink():
  if bigger:
    rect_size = rect_size / 2
    # print( rect_size )
    # print( margin_left, ' ', margin_top, ' ', margin_right, ' ', margin_bottom )
    bigger = false

func drop_me():
  player_data.drop_card()
  # TODO logic for passing this card's data
  pointer.queue_free()
  pointing = false
  shrink()

# == GETTERS == #

func get_card():
  return CARD

func get_pointer_origin():
  return Vector2( rect_size.x / 2, 0 )

func is_hovered():
  return hovered

func is_bigger():
  return bigger

func is_pointing():
  return pointing