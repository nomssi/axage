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
                                  player  TYPE REF TO zcl_axage_actor
                                  actor_node  TYPE REF TO zcl_axage_thing
                                  engine TYPE REF TO zcl_axage_engine
                                  !result TYPE REF TO zcl_axage_result.

  PROTECTED SECTION.
    DATA objects TYPE string_table.
    DATA player TYPE REF TO zcl_axage_actor.
    DATA actor_node TYPE REF TO zcl_axage_thing.
    DATA result  TYPE REF TO zcl_axage_result.
    DATA engine TYPE REF TO zcl_axage_engine.

    DATA param1 TYPE string.
    DATA owned_things TYPE zcl_axage_thing=>tt_index.
    DATA available_things TYPE zcl_axage_thing=>tt_index.
    DATA repository TYPE REF TO zcl_axage_repository.

    METHODS validate IMPORTING into_object  TYPE string
                               operation    TYPE string
                               it_from      TYPE zcl_axage_thing=>tt_index
                     EXPORTING eo_item      TYPE REF TO zcl_axage_thing
                     RETURNING VALUE(valid) TYPE abap_bool.

ENDCLASS.

CLASS lcl_action IMPLEMENTATION.

  METHOD constructor.
    me->objects = objects.
    me->player = player.
    me->actor_node = actor_node.
    me->result = result.
    me->engine = engine.

    owned_things = player->index_list.
    available_things = player->location->index_list.
    repository = engine->repository.
    param1 = VALUE #( objects[ 1 ] OPTIONAL ).
  ENDMETHOD.

  METHOD validate.
    FIELD-SYMBOLS <flag> TYPE abap_bool.

    valid = abap_false.
    CLEAR eo_item.
    IF param1 IS INITIAL.
      result->insert( |{ operation } what?| ).
      result->add_msg( type = 'error'
                       title = |{ operation } { param1 } { into_object }|
                       subtitle = operation
                       description = |{ operation } what?|
                       group = '' ).
    ELSE.
      LOOP AT it_from INTO DATA(from_idx).
        DATA(from) = repository->at_index( from_idx ).
        IF from IS BOUND AND from->name = into_object.
          eo_item = from.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF eo_item IS BOUND.

        DATA(attribute) = |EO_ITEM->CAN_BE_{ to_upper( operation ) }|.
        ASSIGN (attribute) TO <flag>.
        IF sy-subrc = 0 AND <flag> = abap_false.
          result->add( |{ operation } is not allowed for a { into_object }| ).
          result->add_msg( type = 'Error'
                           title = |{ operation } { into_object }|
                           subtitle = player->location->name
                           description = |{ operation } is not allowed for a { into_object }|
                           group = '' ).
        ELSE.
          valid = abap_true.
        ENDIF.
      ELSEIF from IS BOUND AND from->get_list( ) IS INITIAL.
        result->add( |You have nothing to { operation }...| ).
        result->add_msg( type = 'Error'
                         title = |{ operation } { into_object }|
                         subtitle = player->location->name
                         description = |You have nothing to { operation }...|
                         group = '' ).
      ELSE.
        result->add( |There is no { into_object } you can { operation }| ).
        result->add_msg( type = 'Error'
                         title = |{ operation } { into_object }|
                         subtitle = player->location->name
                         description = |There is no { into_object } you can { operation }|
                         group = '' ).
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
    DATA item TYPE REF TO zcl_axage_thing.

    IF validate( EXPORTING into_object = param1
                           operation = 'drop'
                           it_from = owned_things
                 IMPORTING eo_item = item ).
      player->delete_by_name( param1 ).
      player->location->add( item ).
      result->add( |You dropped the { param1 }| ).
      result->add_msg( type = 'Success'
                       title = |drop { param1 }|
                       subtitle = player->location->name
                       description = |You dropped the { param1 }|
                       group = '' ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.
  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.
    LOOP AT objects INTO param1.
      IF validate( EXPORTING into_object = param1
                             operation = 'pickup'
                             it_from = available_things
                   IMPORTING eo_item = item ).
        player->add( item ).
        player->location->delete_by_name( param1 ).
        result->add( |You picked the { param1 } up| ).
        result->add_msg( type = 'Success'
                         title = |pickup { param1 }|
                         subtitle = player->location->name
                         description = |You picked the { param1 } up|
                         group = '' ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_open DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
  PROTECTED SECTION.
    METHODS empty IMPORTING box         TYPE REF TO zcl_axage_thing
                            log         TYPE REF TO zcl_axage_result
                  RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_open IMPLEMENTATION.

  METHOD empty.
    IF box IS INSTANCE OF zif_axage_openable.
      done = abap_true.
      RETURN.
    ENDIF.
    done = abap_true.
    DATA(container) = CAST zif_axage_openable( box ).
    log->add( container->open( player )->get( ) ).   " Open = move all to
    IF container->is_open( ).
      log->add_msg( type = 'Success'
                    title = |open { box->name }|
                    subtitle = player->location->name
                    description = |You opened the { box->name } up|
                    group = '' ).

      DATA finds TYPE string_table.
      LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
        APPEND |a { content->name }| TO finds.
      ENDLOOP.
      log->add( |The { box->name } contains:| ).
      log->addtab( finds ).

      player->add( content ).
    ENDIF.
  ENDMETHOD.

  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.

    IF validate( EXPORTING into_object = param1
                           operation = 'open'
                           it_from = zcl_axage_thing=>merge_index( VALUE #( ( owned_things )
                                                                            ( available_things ) ) )
                 IMPORTING eo_item = item ).
      IF item IS NOT BOUND.
        result->add( |There is no { param1 } to open| ).
      ELSEIF NOT empty( log = result
                        box = item ).
        result->add( |{ item->name } cannot be opened!| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_ask DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    TYPES list_of_actors TYPE STANDARD TABLE OF REF TO zcl_axage_actor WITH EMPTY KEY.

    METHODS execute REDEFINITION.

    METHODS filter_actors IMPORTING actor_node TYPE REF TO zcl_axage_thing
                                    location TYPE REF TO zcl_axage_room
                          RETURNING VALUE(rt_actors) TYPE list_of_actors.
ENDCLASS.

CLASS lcl_ask IMPLEMENTATION.

  METHOD filter_actors.
    LOOP AT actor_node->get_list( ) INTO DATA(thing)
      WHERE table_line IS INSTANCE OF zcl_axage_actor.
      DATA(actor) = CAST zcl_axage_actor( thing ).
      IF actor->get_location( )->name = location->name.
        APPEND actor TO rt_actors.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD execute.
    CHECK validate( EXPORTING into_object = param1
                              operation = 'ask'
                              it_from = owned_things ).

    DATA(name) = param1.
    DATA(actors_in_the_room) = filter_actors( location = player->location
                                              actor_node = actor_node ).

    IF lines( actors_in_the_room ) = 0.
      result->add( 'There is no one here to ask...' ).
    ELSE.
      IF name IS INITIAL.
        result->add( 'Whom do you want to ask?' ).
      ELSE.
        LOOP AT actors_in_the_room INTO DATA(actor)
          WHERE table_line->nameuppercase = name.
          result->addtab( actor->speak( ) ).
        ENDLOOP.
        IF sy-subrc NE 0.
          result->add( |{ name } is not here| ).
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

    IF validate( EXPORTING into_object = param1
                           operation = 'weld'
                           it_from = owned_things ).
      IF validate( into_object = object2
                   it_from = owned_things
                   operation = 'weld into' ).
        DATA(location) = player->location.

        " can_weld_at_this_location ?
        LOOP AT location->get_list( ) INTO DATA(thing)
           WHERE table_line->can_weld = abap_true.

          result->add( |You have welded {  param1 } to {  object2 }| ).
          DATA(new_object_name) = |{ param1 }+{  object2 }|.
          DATA(new_object) = zcl_axage_thing=>new( name = new_object_name
                                                   descr = 'welded'
                                                   engine = engine ).
          " Add new object object1+object2
          player->add( new_object ).

          " Remove 2 objects
          player->delete_by_name( param1 ).
          player->delete_by_name( object2 ).

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
    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( owned_things ) ( available_things ) ) ).

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
    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( owned_things ) ( available_things ) ) ).

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

CLASS lcl_cast DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_cast IMPLEMENTATION.

  METHOD execute.
    DATA lo_item TYPE REF TO zcl_axage_thing.

    IF validate( EXPORTING into_object = param1
                           operation = 'cast'
                           it_from = owned_things
                 IMPORTING eo_item = lo_item ).
      IF lo_item IS BOUND.
        player->location->dark = abap_false.
        result->add( |You cast the spell { lo_item->describe( ) }| ).
      ELSE.
        result->add( |You have not learned that spell yet| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_look DEFINITION INHERITING FROM lcl_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
    METHODS details IMPORTING !object TYPE REF TO zcl_axage_thing
                               log    TYPE REF TO zcl_axage_result
                               location TYPE REF TO zcl_axage_room
                    RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_look IMPLEMENTATION.
  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.
    LOOP AT objects INTO param1.
      IF validate( EXPORTING into_object = param1
                             operation = 'look'
                             it_from = available_things
                   IMPORTING eo_item = item ).
        result->add( |You look at the { param1 }).| ).
        result->add( |You see { item->describe( ) }| ).
        details( log = result
                 location = player->location
                 object = item ).

        result->add_msg( type = 'Success'
                         title = |look at { param1 }|
                         subtitle = player->location->name
                         description = |You looked at the { param1 }|
                         group = '' ).
      ELSEIF validate( EXPORTING into_object = param1
                                 operation = 'look'
                                 it_from = owned_things
                       IMPORTING eo_item = item ).
        result->add( |You look at the { param1 } you are carrying.| ).
        result->add( |You see { item->describe( ) }| ).

        result->add_msg( type = 'Success'
                         title = |look at { param1 }|
                         subtitle = player->location->name
                         description = |You looked at the { param1 } you are carrying|
                         group = '' ).

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD details.
    done = abap_false.
    IF NOT object IS INSTANCE OF zif_axage_openable.
      RETURN.
    ENDIF.
    DATA(container) = CAST zif_axage_openable( object ).
    container->details( location ).
    IF container->is_open( ).
      log->add_msg( type = 'Success'
                    title = |look at { object->name }|
                    subtitle = location->name
                    description = |You look at details of { object->name }|
                    group = '' ).

      DATA finds TYPE string_table.
      LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
        APPEND content->describe(  ) TO finds.
        location->add( content ).
      ENDLOOP.
      log->add( |The { object->name } has:| ).
      log->addtab( finds ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
