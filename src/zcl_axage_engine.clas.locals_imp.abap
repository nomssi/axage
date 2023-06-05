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
    TYPES tt_thing_list TYPE STANDARD TABLE OF REF TO zcl_axage_thing_list WITH EMPTY KEY.
    DATA objects TYPE string_table.
    DATA player TYPE REF TO zcl_axage_actor.
    DATA actors TYPE REF TO zcl_axage_thing_list.
    DATA result  TYPE REF TO zcl_axage_result.

    DATA param1 TYPE string.
    DATA owned_things TYPE REF TO zcl_axage_thing_list.
    DATA available_things TYPE REF TO zcl_axage_thing_list.

    METHODS validate1 IMPORTING operation TYPE string
                                it_from TYPE tt_thing_list
                      EXPORTING eo_item TYPE REF TO zcl_axage_thing
                      RETURNING VALUE(valid) TYPE abap_bool.
    METHODS validate IMPORTING into_object TYPE string
                               operation TYPE string
                               it_from TYPE tt_thing_list
                     EXPORTING eo_item TYPE REF TO zcl_axage_thing
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
    valid = validate( EXPORTING into_object = param1
                                operation = operation
                                it_from = it_from
                      IMPORTING eo_item = eo_item ).
  ENDMETHOD.

  METHOD validate.
    FIELD-SYMBOLS <flag> TYPE abap_bool.

    valid = abap_false.
    CLEAR eo_item.
    IF param1 IS INITIAL.
      result->insert( |{ operation } what?| ).
    ELSE.
      LOOP AT it_from INTO DATA(from).
        IF from->exists( into_object ).
          eo_item = from->get( into_object ).         " variable is used dynamically
          EXIT.
        ENDIF.
      ENDLOOP.
      IF eo_item IS BOUND.

        DATA(attribute) = |EO_ITEM->CAN_BE_{ to_upper( operation ) }|.
        ASSIGN (attribute) TO <flag>.
        IF sy-subrc = 0 AND <flag> = abap_false.
          result->add( |{ operation } is not allowed for a { into_object }| ).
        ELSE.
          valid = abap_true.
        ENDIF.
      ELSEIF from->get_list( ) IS INITIAL.
        result->add( |You have nothing to { operation }...| ).
      ELSE.
        result->add( |There is no { into_object } you can { operation }| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_drop DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_drop IMPLEMENTATION.

  METHOD execute.
    IF validate1( it_from = VALUE #( ( owned_things ) )
                  operation = 'drop' ).
      DATA(item) = owned_things->get( param1 ).
      owned_things->delete( param1 ).
      available_things->add( item ).
      result->add( |You dropped the { param1 }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.
  METHOD execute.
    LOOP AT objects INTO param1.
      IF validate1( it_from = VALUE #( ( available_things ) )
                    operation = 'pickup' ).
        DATA(item) = available_things->get( param1 ).
        owned_things->add( item ).
        available_things->delete( param1 ).
        result->add( |You picked the { param1 } up| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_open DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_open IMPLEMENTATION.

  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.

    IF NOT validate1( EXPORTING operation = 'open'
                                it_from = VALUE #( ( owned_things )
                                                   ( available_things )  )
                      IMPORTING eo_item = item ).
      RETURN.
    ENDIF.

    IF param1 IS NOT INITIAL.

      IF item IS INSTANCE OF zif_axage_openable.
        DATA(container) = CAST zif_axage_openable( item ).
        result->add( container->open( player->things )->get( ) ).
        IF container->is_open( ).

          DATA finds TYPE string_table.
          LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
            APPEND |a { content->name }| TO finds.
          ENDLOOP.
          result->add( |The { item->name } contains:| ).
          result->addtab( finds ).

          player->things->add( content ).
        ENDIF.
      ELSEIF item IS BOUND.
        result->add( |{ item->name } cannot be opened!| ).
      ELSE.
        result->add( |You cannot open that { param1 }| ).
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
    CHECK validate1( it_from = VALUE #( ( owned_things ) )
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
                  it_from = VALUE #( ( owned_things ) ) ).
      IF validate( into_object = object2
                   it_from = VALUE #( ( owned_things ) )
                   operation = 'weld into' ).
        DATA(available_things) = player->location->things.

          " can_weld_at_this_location ?
          LOOP AT player->location->things->get_list( ) INTO DATA(thing) WHERE TABLE_LINE->can_weld = abap_true.


            result->add( |You have welded {  param1 } to {  object2 }| ).
            DATA(new_object_name) = |{ param1 }+{  object2 }|.

            " Add new object object1+object2
            owned_things->add( available_things->get( new_object_name ) ).

            " Remove 2 objects
            owned_things->delete( param1 ).
            owned_things->delete( object2 ).

            RETURN.
          ENDLOOP..

          result->add( 'There is no Welding Torch here...' ).
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
    DATA item_subject TYPE REF TO zcl_axage_thing.
    DATA item_object TYPE REF TO zcl_axage_thing.

    DATA(splash_subject) = param1.
    DATA(splash_object) = VALUE #( objects[ 2 ] OPTIONAL ).
    DATA(things_at_location) = VALUE tt_thing_list( ( owned_things ) ( available_things ) ).

    IF validate( EXPORTING into_object = splash_subject
                           it_from = things_at_location
                           operation = 'splash'
                 IMPORTING eo_item = item_subject ).

      IF validate( EXPORTING into_object = splash_object
                             it_from = things_at_location
                             operation = 'splash_into'
                   IMPORTING eo_item = item_object ).
        result->add( |You have splashed { splash_subject } on { splash_object }| ).
      ELSEIF item_subject IS BOUND.
        result->add( |You cannot splash { splash_subject } into { splash_object }| ).
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
    DATA item_subject TYPE REF TO zcl_axage_thing.
    DATA item_object TYPE REF TO zcl_axage_thing.

    DATA(dunk_subject) = param1.
    DATA(dunk_object) = VALUE #( objects[ 2 ] OPTIONAL ).
    DATA(things_at_location) = VALUE tt_thing_list( ( owned_things ) ( available_things ) ).

    IF validate( EXPORTING into_object = dunk_subject
                           it_from = things_at_location
                           operation = 'dunk'
                 IMPORTING eo_item = item_subject ).

      IF validate( EXPORTING into_object = dunk_object
                             it_from = things_at_location
                             operation = 'dunk_into'
                   IMPORTING eo_item = item_object ).
        IF item_object IS BOUND AND item_object->can_be_dunk_into = abap_true.

          result->add( |You have dunked the { dunk_subject } into the { dunk_object }| ).
*          DATA(new_object_name) = |WET { param1 }|.
*
*          " Add new object object1+object2
*          owned_things->add( available_things->get( new_object_name ) ).

          " Remove 1 objects
*          owned_things->delete( param1 ).

        ELSE.
          result->add( |You cannot dunk into { dunk_object }| ).
        ENDIF.
      ENDIF.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
