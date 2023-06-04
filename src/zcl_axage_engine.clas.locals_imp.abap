*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

INTERFACE lif_axage_command.
  METHODS execute.
ENDINTERFACE.

CLASS lcl_action DEFINITION ABSTRACT.
  PUBLIC SECTION.
    INTERFACES lif_axage_command ABSTRACT METHODS execute.
    ALIASES execute FOR lif_axage_command~execute.
    METHODS constructor IMPORTING objects TYPE string_table
                                  player   TYPE REF TO zcl_axage_actor
                                  actors   TYPE REF TO zcl_axage_thing_list
                                  !result  TYPE REF TO zcl_axage_result.

  PROTECTED SECTION.
    DATA objects TYPE string_table.
    DATA player TYPE REF TO zcl_axage_actor.
    DATA actors TYPE REF TO zcl_axage_thing_list.
    DATA result  TYPE REF TO zcl_axage_result.

    DATA param1 TYPE string.
    DATA owned_things TYPE REF TO zcl_axage_thing_list.
    DATA available_things TYPE REF TO zcl_axage_thing_list.

    METHODS validate1 IMPORTING operation TYPE string
                                from TYPE REF TO zcl_axage_thing_list
                      RETURNING VALUE(valid) TYPE abap_bool.
    METHODS validate IMPORTING param TYPE string
                               operation TYPE string
                               from TYPE REF TO zcl_axage_thing_list
                     RETURNING VALUE(valid) TYPE abap_bool.

ENDCLASS.

CLASS lcl_action IMPLEMENTATION.

  METHOD constructor.
    me->objects = objects.
    me->player = player.
    me->actors = actors.
    me->result = result.

    owned_things = player->things.
    available_things = player->location->things.
    param1 = VALUE #( objects[ 1 ] OPTIONAL ).
  ENDMETHOD.

  METHOD validate1.
    valid = validate( param = param1
                      operation = operation
                      from = from ).
  ENDMETHOD.

  METHOD validate.
    valid = abap_false.
    IF param1 IS INITIAL.
      result->add( |{ operation } what?| ).
    ELSEIF from->exists( param1 ).
      result->add( |You { operation } the { param }| ).
      valid = abap_true.
    ELSEIF from->get_list( ) IS INITIAL.
      result->add( |You have nothing to { operation }...| ).
    ELSE.
      result->add( |There is no { param } you can { operation }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_drop DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_drop IMPLEMENTATION.

  METHOD execute.
    IF validate1( from = owned_things
                  operation = 'drop' ).
      DATA(item) = owned_things->get( param1 ).
      owned_things->delete( param1 ).
      available_things->add( item ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.
  METHOD execute.
    IF validate1( from = available_things
                  operation = 'pickup' ).
      DATA(item) = available_things->get( param1 ).
      owned_things->add( item ).
      available_things->delete( param1 ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_open DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_open IMPLEMENTATION.

  METHOD execute.
    CHECK validate1( operation = 'open'
                     from = owned_things ).

    DATA(box)  = param1.

    IF box IS INITIAL.
    ELSEIF     owned_things->get_list( )  IS INITIAL
           AND available_things->get_list( ) IS INITIAL.
      result->add( 'There is nothing to open...' ).
    ELSE.
      IF owned_things->exists( box ).
        DATA(thing) = owned_things->get( box ).
      ELSEIF available_things->exists( box ).
        thing = available_things->get( box ).
      ENDIF.

      IF thing IS INSTANCE OF zif_axage_openable.
        DATA(thing_to_open) = CAST zif_axage_openable( thing ).
        result->add( thing_to_open->open( player->things )->get( ) ).
        IF thing_to_open->is_open( ).
          DATA finds TYPE string_table.
          LOOP AT thing_to_open->get_content( )->get_list( ) INTO DATA(content).
            APPEND |a { content->name }| TO finds.
          ENDLOOP.
          result->add( |The { thing->name } contains:| ).
          result->addtab( finds ).
          player->things->add( content ).
        ENDIF.
      ELSEIF thing IS BOUND.
        result->add( |{ thing->name } cannot be opened!| ).
      ELSE.
        result->add( |You cannot open that { box }| ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_ask DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    TYPES list_of_actors TYPE STANDARD TABLE OF REF TO zcl_axage_actor WITH EMPTY KEY.

    METHODS execute REDEFINITION.

    METHODS filter_actors IMPORTING things TYPE REF TO zcl_axage_thing_list
                                    room TYPE REF TO zcl_axage_room
                          RETURNING VALUE(rt_actors) TYPE list_of_actors.
ENDCLASS.

CLASS lcl_ask IMPLEMENTATION.

  METHOD filter_actors.
    LOOP AT things->get_list( ) INTO DATA(thing) WHERE table_line IS INSTANCE OF zcl_axage_actor.
      DATA(actor) = CAST zcl_axage_actor( thing ).
      IF actor->get_location( ) = room.
        APPEND actor TO rt_actors.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD execute.
    CHECK validate1( from = owned_things
                     operation = 'ask' ).

    DATA(name) = param1.
    DATA(actors_in_the_room) = filter_actors( room = player->location
                                              things = actors ).

    IF actors_in_the_room IS INITIAL.
      result->add( 'There is no one here to ask...' ).
    ELSE.
      IF name IS INITIAL.
        result->add( 'Whom do you want to ask?' ).
      ELSE.
        LOOP AT actors_in_the_room INTO DATA(actor) WHERE TABLE_LINE->nameUpperCase = name.
          result->addtab( actor->speak( ) ).
        ENDLOOP.
        IF sy-subrc NE 0.
          result->add( |You cannot ask { name }| ).
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_weld DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_weld IMPLEMENTATION.
  METHOD execute.
   DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).
    IF validate1( operation = 'weld'
                  from = owned_things ).
      IF validate( param = object2
                   from = owned_things
                   operation = 'weld to' ).
        DATA(available_things) = player->location->things.
          IF player->location->things->exists( 'WELDING TORCH' ).

            result->add( |You have welded {  param1 } to {  object2 }| ).
            DATA(new_object_name) = |{ param1 }+{  object2 }|.

            " Add new object object1+object2
            owned_things->add( available_things->get( new_object_name ) ).

            " Remove 2 objects
            owned_things->delete( param1 ).
            owned_things->delete( object2 ).

          ELSE.
            result->add( 'There is no Welding Torch here...' ).
          ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_splash DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_splash IMPLEMENTATION.
  METHOD execute.
    DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).

    IF validate1( operation = 'splash'
                  from = owned_things ).

      IF validate( param = object2
                   from = available_things
                   operation = 'splash on' ).
            result->add( |You have splashed {  param1 } on {  object2 }| ).

      ENDIF.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_dunk DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_dunk IMPLEMENTATION.
  METHOD execute.
    DATA(object2) = VALUE #( objects[ 2 ] OPTIONAL ).

    IF NOT validate1( operation = 'dunk'
                      from = owned_things ).
      RETURN.
    ENDIF.

    IF NOT validate( param = object2
                     from = available_things
                     operation = 'dunk in' ).
      RETURN.
    ENDIF.

    IF player->location->things->exists( 'MOP' ).

      result->add( |You have dunk {  param1 } in {  object2 }| ).
      DATA(new_object_name) = |WET { param1 }|.

      " Add new object object1+object2
      owned_things->add( available_things->get( new_object_name ) ).

      " Remove 1 objects
      owned_things->delete( param1 ).

    ELSE.
      result->add( 'There is no water here...' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
