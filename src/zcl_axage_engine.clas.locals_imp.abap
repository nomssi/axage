*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_command DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_command IMPLEMENTATION.

  METHOD execute.
    DATA lo_item TYPE REF TO zcl_axage_thing.

    IF validate( EXPORTING into_object = param1
                           operation = operation
                           it_from = owned_things
                 IMPORTING eo_item = lo_item ).
      IF lo_item IS BOUND.
        IF lo_item IS INSTANCE OF zif_axage_command.
          CAST zif_axage_command( lo_item )->execute( engine = engine
                                                      result = result ).
        ELSE.
          result->add( |You cannot use { operation } on { param1 }.| ).
        ENDIF.
      ELSE.
        result->add( |You have not learned that yet| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_drop DEFINITION INHERITING FROM zcl_axage_action.
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
      result->success_msg( title = |drop { param1 }|
                           subtitle = player->location->name
                           description = |You dropped the { param1 }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.
  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.

    mandatory_params( 1 ).

    LOOP AT objects INTO param1.
      IF validate( EXPORTING into_object = param1
                             operation = operation
                             it_from = available_things
                   IMPORTING eo_item = item ).
        player->add( item ).
        player->location->delete_by_name( param1 ).
        result->add( |You picked the { param1 } up| ).
        result->success_msg( title = |pickup { param1 }|
                             subtitle = player->location->name
                             description = |You picked the { param1 } up| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_open DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
  PROTECTED SECTION.
    METHODS empty IMPORTING box         TYPE REF TO zcl_axage_thing
                            log         TYPE REF TO zcl_axage_result
                  RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_open IMPLEMENTATION.

  METHOD empty.
    done = abap_false.
    IF box IS NOT INSTANCE OF zif_axage_openable.
      RETURN.
    ENDIF.
    DATA(container) = CAST zif_axage_openable( box ).
    log->add( container->open( player )->get( ) ).   " Open = move all to
    IF container->is_open( ).
      done = abap_true.

      DATA finds TYPE string_table.
      LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
        APPEND |a { content->name }| TO finds.
      ENDLOOP.
      log->add( |The { box->name } contains:| ).
      log->addtab( finds ).
      log->add( |You have picked up the contains of the { box->name }.| ).

      player->add( content ).
      log->success_msg(
                    title = |open { box->name }|
                    subtitle = player->location->name
                    description = |You now have to content of the { box->name }| ).
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

CLASS lcl_ask DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    TYPES list_of_actors TYPE STANDARD TABLE OF REF TO zcl_axage_actor WITH EMPTY KEY.

    METHODS execute REDEFINITION.

    METHODS filter_actors IMPORTING location TYPE REF TO zcl_axage_room
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
    DATA(name) = param1.
    DATA(actors_in_the_room) = filter_actors( location = player->location ).

    IF lines( actors_in_the_room ) = 0.
      result->add( 'There is no one here to ask...' ).
    ELSE.
      IF name IS INITIAL.
        result->add( 'Whom do you want to ask?' ).
      ELSE.
        LOOP AT actors_in_the_room INTO DATA(actor) WHERE table_line->nameuppercase = name.
          result->addtab( actor->speak( ) ).
        ENDLOOP.
        IF sy-subrc NE 0.
          result->add( |{ name } is not here| ).
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_weld DEFINITION INHERITING FROM zcl_axage_action.
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
                                                   repository = engine->repository ).
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

CLASS lcl_splash DEFINITION INHERITING FROM zcl_axage_action.
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

CLASS lcl_dunk DEFINITION INHERITING FROM zcl_axage_action.
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

CLASS lcl_look DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
    METHODS details IMPORTING !object TYPE REF TO zcl_axage_thing
                               log    TYPE REF TO zcl_axage_result
                               location TYPE REF TO zcl_axage_thing
                    RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_look IMPLEMENTATION.
" TO DO: Allow variant LOOK AT ...
  METHOD execute.
    DATA item TYPE REF TO zcl_axage_thing.

    mandatory_params( 1 ).
    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( available_things ) ( owned_things ) ) ).

    LOOP AT objects INTO param1.
      IF validate( EXPORTING into_object = param1
                             operation = operation
                             it_from = things_at_location
                   IMPORTING eo_item = item ).
        result->add( |You see { item->describe( ) }| ).
        details( log = result
                 location = player
                 object = item ).

        result->success_msg( title = |look at { param1 }|
                             subtitle = player->location->name
                             description = |You looked at the { param1 }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD details.
    DATA finds TYPE string_table.

    done = abap_false.
    IF object IS NOT INSTANCE OF zif_axage_openable.
      RETURN.
    ENDIF.
    DATA(container) = CAST zif_axage_openable( object ).
    container->details( location ).
    IF NOT container->is_open( ).
      RETURN.
    ENDIF.

    log->success_msg( title = |look at { object->name }|
                      subtitle = location->name
                      description = |You look at details of { object->name }| ).

    LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
      APPEND content->describe( ) TO finds.
      location->add( content ).
    ENDLOOP.
    log->add( |The { object->name } has:| ).
    log->addtab( finds ).
  ENDMETHOD.

ENDCLASS.
