*"* use this source file for your ABAP unit test classes
CLASS ltcl_engine DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO ycl_axage_engine.
    METHODS:
      setup,
      map_simple FOR TESTING RAISING cx_static_check,
      take_and_drop FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_engine IMPLEMENTATION.

  METHOD map_simple.

    "floor plan configuration
    DATA(room_left) = cut->new_room( name = 'LEFT' descr = 'Left room' ).
    DATA(room_right) = cut->new_room( name = 'RIGHT' descr = 'Right room' ).
    room_left->set_exits( e = room_right ).
    room_right->set_exits( w = room_left ).
    cut->map->add_room( room_left ).
    cut->map->add_room( room_right ).
    cut->player->set_location( room_left ).

    "GO WEST -> not possible -> current position still ROOM_LEFT
    cut->interprete( 'W' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->player->get_location( )
      exp = room_left ).
    "GO EAST -> leads to room_right
    cut->interprete( 'e' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->player->get_location( )
      exp = room_right ).
  ENDMETHOD.

  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD take_and_drop.
    "floor plan configuration
    DATA(room_left) = cut->new_room( name = 'LEFT' descr = 'Left room' ).
    DATA(room_right) = cut->new_room( name = 'RIGHT' descr = 'Right room' ).
    room_left->set_exits( e = room_right ).
    DATA(bottle) = cut->new_object( name = 'BOTTLE' state = 'an empty bottle' descr = 'whiskey' ).
    room_left->add( bottle ).
    room_right->set_exits( w = room_left ).
    cut->map->add_room( room_left ).
    cut->map->add_room( room_right ).

    cl_abap_unit_assert=>assert_false(
      act = room_right->exists( 'BOTTLE' )
      msg = 'TAKE and DROP Initial state Error' ).

    cut->player->set_location( room_left ).
    cut->interprete( 'TAKE BOTTLE' ).
    cut->interprete( 'e' ).
    cut->interprete( 'DROP BOTTLE' ).

    cl_abap_unit_assert=>assert_true(
      act = room_right->exists( 'BOTTLE' )
      msg = 'TAKE and DROP error' ).

  ENDMETHOD.

ENDCLASS.
