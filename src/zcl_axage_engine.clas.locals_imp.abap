*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_command DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_command IMPLEMENTATION.

  METHOD execute.
    DATA lt_item TYPE tt_thing.

    IF validate( EXPORTING it_from = owned_things
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        IF lo_item IS INSTANCE OF zif_axage_command.
          CAST zif_axage_command( lo_item )->execute( engine = engine
                                                      result = result ).
        ELSE.
          result->add( |You cannot use { operation } on { lo_item->name }.| ).
        ENDIF.
      ENDLOOP.
      IF sy-subrc NE 0.
        result->add( |You do not know how to do that (yet?)| ).
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
    DATA lt_item TYPE tt_thing.

    IF validate( EXPORTING it_from = owned_things
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        player->delete_by_name( lo_item->name ).
        player->location->add( lo_item ).
        result->success_msg( title = |drop { lo_item->name }|
                             subtitle = player->location->name
                             description = |You dropped the { lo_item->name }| ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.
  METHOD execute.
    DATA lt_item TYPE tt_thing.

    IF validate( EXPORTING it_from = available_things
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        player->add( lo_item ).
        player->location->delete_by_name( lo_item->name ).
        result->success_msg( title = |pickup { lo_item->name }|
                             subtitle = player->location->name
                             description = |You picked the { lo_item->name } up| ).
      ENDLOOP.
    ENDIF.
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

      player->add( content ).
      log->success_msg( title = |open { box->name }|
                        subtitle = player->location->name
                        description = |You now have to content of { box->name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD execute.
    DATA lt_item TYPE tt_thing.

    IF validate( EXPORTING it_from = zcl_axage_thing=>merge_index( VALUE #( ( owned_things )
                                                                            ( available_things ) ) )
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        IF NOT empty( log = result
                      box = lo_item ).
          result->add( |{ lo_item->name } cannot be opened!| ).
        ENDIF.
      ENDLOOP.
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
    DATA(actors_in_the_room) = filter_actors( location = player->location ).

    IF lines( actors_in_the_room ) = 0.
      result->add( 'There is no one here to ask...' ).
    ELSE.
      LOOP AT objects INTO DATA(actor_name).
        LOOP AT actors_in_the_room INTO DATA(actor) WHERE table_line->nameuppercase = actor_name.
          result->addtab( actor->speak( ) ).
        ENDLOOP.
        IF sy-subrc NE 0.
          result->add( |{ actor_name } is not here| ).
        ENDIF.
      ENDLOOP..
      IF sy-subrc IS NOT INITIAL.
        result->add( 'Whom do you want to ask?' ).
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

    IF validate( it_from = owned_things
                 number_of_parameters = 2 ).
        DATA(location) = player->location.
        DATA(object1) = objects[ 1 ].
        DATA(object2) = objects[ 2 ].

        " can_weld_at_this_location ?
        LOOP AT location->get_list( ) INTO DATA(thing).
          CHECK line_exists( thing->capable_of[ table_line = zcl_axage=>c_action_weld ] ).

          result->add( |You have welded {  object1 } to {  object2 }| ).
          DATA(new_object_name) = |{ object1 }+{  object2 }|.
          DATA(new_object) = zcl_axage_thing=>new( name = new_object_name
                                                   descr = |{ object1 } welded to { object2 }|
                                                   repository = engine->repository ).
          " Add new object object1+object2
          player->add( new_object ).

          " Remove 2 objects
          player->delete_by_name( object1 ).
          player->delete_by_name( object2 ).

          RETURN.
        ENDLOOP..

        result->add( 'There is no Welding Torch here...' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_splash DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_splash IMPLEMENTATION.

  METHOD execute.
    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( owned_things ) ( available_things ) ) ).

    IF validate( it_from = things_at_location
                  number_of_parameters = 2 ).
      DATA(splash_subject) = objects[ 1 ].
      DATA(splash_object) = objects[ 2 ].

      result->add( |You have splashed { splash_subject } on { splash_object }| ).

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lcl_dunk DEFINITION INHERITING FROM zcl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_dunk IMPLEMENTATION.

  METHOD execute.
    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( owned_things ) ( available_things ) ) ).

    IF validate( it_from = things_at_location
                 number_of_parameters = 2 ).
      DATA(dunk_subject) = objects[ 1 ].
      DATA(dunk_object) = objects[ 2 ].

      result->add( |You have dunked the { dunk_subject } into the { dunk_object }| ).

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
  METHOD execute.
    DATA lt_item TYPE tt_thing.

    DATA(things_at_location) = zcl_axage_thing=>merge_index( VALUE #( ( available_things ) ( owned_things ) ) ).

    " Allow variant LOOK AT without error message
    IF lines( objects ) > 1 AND objects[ 1 ] = 'AT'.
      DELETE objects INDEX 1.
    ENDIF.

    IF validate( EXPORTING it_from = things_at_location
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        result->add( |You see { lo_item->describe( ) }| ).
        details( log = result
                 location = player->location
                 object = lo_item ).

        result->success_msg( title = |look at { lo_item->name }|
                             subtitle = player->location->name
                             description = |You looked at the { lo_item->name }| ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD details.
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
      location->add( content ).
      log->success_msg( title = content->name
                        subtitle = location->name
                        description = content->describe( ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
