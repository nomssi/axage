*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

CLASS lcl_command DEFINITION INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_command IMPLEMENTATION.

  METHOD execute.
    DATA lt_item TYPE tt_thing.

    processed = abap_false.
    IF validate( EXPORTING it_from = engine->player->index_list
                 IMPORTING et_item = lt_item ).
      LOOP AT lt_item INTO DATA(lo_item).
        IF lo_item IS INSTANCE OF yif_axage_command.
          CAST yif_axage_command( lo_item )->execute( engine = engine
                                                      log = log ).
          processed = abap_true.
        ELSE.
          warning( |You cannot use { operation } on { lo_item->name }.| ).
        ENDIF.
      ENDLOOP.
      IF sy-subrc NE 0.
        warning( |You do not know how to do that (yet?)| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_inventory DEFINITION INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
ENDCLASS.

CLASS lcl_inventory IMPLEMENTATION.

  METHOD execute.
    DATA lt_msg TYPE string_table.

    DATA(your_things) = engine->player->get_list( ).

    processed = abap_true.
    IF lines( your_things ) IS INITIAL.
      APPEND |Your inventory is empty...| TO lt_msg.
    ELSE.
      APPEND |You are carrying:| TO lt_msg.
    ENDIF.
    LOOP AT your_things INTO DATA(thing_inv).
      APPEND thing_inv->describe( with_state = abap_false ) TO lt_msg.
    ENDLOOP.

    success( concat_lines_of( table = lt_msg sep = |\n| ) ).
  ENDMETHOD.

ENDCLASS.

CLASS lcl_move DEFINITION ABSTRACT INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
    METHODS get_locations ABSTRACT.
  PROTECTED SECTION.
    DATA from_storage TYPE REF TO ycl_axage_thing.
    DATA to_storage TYPE REF TO ycl_axage_thing.
ENDCLASS.

CLASS lcl_move IMPLEMENTATION.
  METHOD execute.
    DATA lt_item TYPE tt_thing.
    DATA lt_msg TYPE string_table.

    get_locations( ).

    IF validate( EXPORTING it_from = from_storage->index_list
                 IMPORTING et_item = lt_item ).
      processed = abap_true.

      LOOP AT lt_item INTO DATA(lo_item).
        from_storage->delete_by_name( lo_item->name ).
        to_storage->add( lo_item ).
        APPEND |You { operation } the { lo_item->name }| TO lt_msg.
      ENDLOOP.
      IF sy-subrc EQ 0.
        success( concat_lines_of( table = lt_msg sep = |\n| ) ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_drop DEFINITION INHERITING FROM lcl_move.
  PUBLIC SECTION.
    METHODS get_locations REDEFINITION.
ENDCLASS.

CLASS lcl_drop IMPLEMENTATION.

  METHOD get_locations.
    from_storage = engine->player.
    to_storage = engine->player->location.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_pickup DEFINITION INHERITING FROM lcl_move.
  PUBLIC SECTION.
    METHODS get_locations REDEFINITION.
ENDCLASS.

CLASS lcl_pickup IMPLEMENTATION.

  METHOD get_locations.
    from_storage = engine->player->location.
    to_storage = engine->player.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_open DEFINITION INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
  PROTECTED SECTION.
    METHODS empty IMPORTING box         TYPE REF TO ycl_axage_thing
                            log         TYPE REF TO ycl_axage_log
                  RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_open IMPLEMENTATION.

  METHOD empty.
    DATA lt_msg TYPE string_table.

    done = abap_false.
    IF box IS NOT INSTANCE OF yif_axage_openable.
      RETURN.
    ENDIF.
    DATA(container) = CAST yif_axage_openable( box ).
    container->open( things = engine->player
                     log = log ).
    IF container->is_open( ).
      done = abap_true.

      " Open = move all to
      LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
        APPEND |{ content->prefix }{ content->name }| TO lt_msg.
      ENDLOOP.

      engine->player->add( content ).
      success( |You now have to content of { box->name }\n{
                 concat_lines_of( table = lt_msg sep = |\n| ) }| ).
    ENDIF.
  ENDMETHOD.

  METHOD execute.
    DATA lt_item TYPE tt_thing.

    DATA(owned_things) = engine->player->index_list.
    DATA(available_things) = engine->player->location->index_list.

    IF validate( EXPORTING it_from = ycl_axage_thing=>merge_index( VALUE #( ( owned_things )
                                                                            ( available_things ) ) )
                 IMPORTING et_item = lt_item ).
      processed = abap_true.
      LOOP AT lt_item INTO DATA(lo_item).
        IF NOT empty( log = log
                      box = lo_item ).
          error( |{ lo_item->name } could not be opened!| ).
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_ask DEFINITION INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    TYPES list_of_actors TYPE STANDARD TABLE OF REF TO ycl_axage_actor WITH EMPTY KEY.

    METHODS execute REDEFINITION.

    METHODS filter_actors IMPORTING location TYPE REF TO ycl_axage_room
                          RETURNING VALUE(rt_actors) TYPE list_of_actors.
ENDCLASS.

CLASS lcl_ask IMPLEMENTATION.

  METHOD filter_actors.
    LOOP AT engine->actor_node->get_list( ) INTO DATA(thing)
      WHERE table_line IS INSTANCE OF ycl_axage_actor.
      DATA(actor) = CAST ycl_axage_actor( thing ).
      IF actor->get_location( )->name = location->name.
        APPEND actor TO rt_actors.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD execute.
    DATA(actors_in_the_room) = filter_actors( location = engine->player->location ).

    IF lines( actors_in_the_room ) = 0.
      error( 'There is no one here to ask...' ).
    ELSE.
      processed = abap_true.
      LOOP AT objects INTO DATA(actor_name).
        LOOP AT actors_in_the_room INTO DATA(actor) WHERE table_line->nameuppercase = actor_name.
          info( concat_lines_of( table = actor->speak( ) sep = |\n|  ) ).
        ENDLOOP.
        IF sy-subrc <> 0.
          error( |{ actor_name } is not here| ).
        ENDIF.
      ENDLOOP.
      IF sy-subrc IS NOT INITIAL.
        error( 'Whom do you want to ask?' ).
      ENDIF.

    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_side_effect DEFINITION ABSTRACT INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
  PROTECTED SECTION.
    METHODS things_at_location RETURNING VALUE(rt_list) TYPE ycl_axage=>tt_index.
ENDCLASS.

CLASS lcl_side_effect IMPLEMENTATION.

  METHOD things_at_location.
    DATA(location) = engine->player->location.

    DATA(owned_things) = engine->player->index_list.
    DATA(available_things) = location->index_list.

    rt_list = ycl_axage_thing=>merge_index( VALUE #( ( owned_things ) ( available_things ) ) ).
  ENDMETHOD.

  METHOD execute.
    DATA lt_thing   TYPE tt_thing.
    DATA ls_mapping TYPE ycl_axage=>ts_combine.
    DATA separator  TYPE string.

    IF NOT ( validate( EXPORTING it_from = things_at_location( )
                                 number_of_parameters = 2
                       IMPORTING et_item = lt_thing )
              AND lines( lt_thing ) > 1 ).
      RETURN.
    ENDIF.
    DATA(action_subject) = lt_thing[ 1 ].
    DATA(action_object) = lt_thing[ 2 ].

    processed = abap_true.

    IF engine->combine( EXPORTING action = operation
                                  object1 = lt_thing[ 1 ]
                                  object2 = lt_thing[ 2 ]
                        IMPORTING es_mapping = ls_mapping ).

      " Remove objects
      CASE ls_mapping-category.
        WHEN ycl_axage=>c_combine_category_on.
          separator = 'on'.
          engine->player->delete_by_name( action_object->name ).

        WHEN ycl_axage=>c_combine_category_into.
          separator = 'into'.
          engine->player->delete_by_name( action_subject->name ).

        WHEN ycl_axage=>c_combine_category_merge.
          separator = 'to'.
          engine->player->delete_by_name( action_subject->name ).
          engine->player->delete_by_name( action_object->name ).

        WHEN OTHERS.
          separator = 'to'.
      ENDCASE.

      success( |You { operation } {  action_subject->name } { separator } {  action_object->name }| ).
    ELSE.
      error( |{ operation } {  action_subject->name } {  action_object->name } failed| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_weld DEFINITION INHERITING FROM lcl_side_effect.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
  PROTECTED SECTION.
    METHODS things_at_location REDEFINITION.
ENDCLASS.

CLASS lcl_weld IMPLEMENTATION.

  METHOD things_at_location.
    DATA(owned_things) = engine->player->index_list.

    rt_list = owned_things.
  ENDMETHOD.

  METHOD execute.
    DATA lt_thing TYPE tt_thing.

    DATA(location) = engine->player->location.

    " can_weld_at_this_location ?
    DATA(can_weld) = abap_false.
    LOOP AT location->get_list( ) INTO DATA(thing).
      IF NOT line_exists( thing->capable_of[ table_line = operation ] ).
        CONTINUE.
      ENDIF.
      can_weld = abap_true.
      EXIT.
    ENDLOOP.

    IF can_weld = abap_false.
      error( 'There is no Welding Torch here...' ).
      RETURN.
    ENDIF.

    super->execute( ).

  ENDMETHOD.

ENDCLASS.

CLASS lcl_splash DEFINITION INHERITING FROM lcl_side_effect.
ENDCLASS.

CLASS lcl_dunk DEFINITION INHERITING FROM lcl_side_effect.
ENDCLASS.

CLASS lcl_look DEFINITION INHERITING FROM ycl_axage_action.
  PUBLIC SECTION.
    METHODS execute REDEFINITION.
    METHODS details IMPORTING !object TYPE REF TO ycl_axage_thing
                    RETURNING VALUE(done) TYPE abap_bool.
ENDCLASS.

CLASS lcl_look IMPLEMENTATION.
  METHOD execute.
    DATA lt_item TYPE tt_thing.

    IF engine->player->location->dark = abap_true.
      log->add( 'You cannot see in the dark.' ).
      RETURN.
    ENDIF.

    DATA(owned_things) = engine->player->index_list.
    DATA(available_things) = engine->player->location->index_list.
    DATA(things_at_location) = ycl_axage_thing=>merge_index( VALUE #( ( available_things ) ( owned_things ) ) ).

    " Allow variant LOOK AT.. LOOK AROUND without error message
    DELETE objects WHERE table_line = 'AT' OR table_line = 'AROUND'.

    IF objects IS INITIAL.
      engine->player->location->look_around( log ).

    ELSEIF validate( EXPORTING it_from = things_at_location
                     IMPORTING et_item = lt_item ).
      processed = abap_true.
      LOOP AT lt_item INTO DATA(lo_item).
        details( object = lo_item ).
      ENDLOOP.
    ENDIF.
  ENDMETHOD.

  METHOD details.
    DATA lt_msg TYPE string_table.
    DATA lv_msg TYPE string.

    done = abap_false.
    lv_msg = |You see { object->describe( ) }\n|.

    IF object IS NOT INSTANCE OF yif_axage_openable.
      success( lv_msg ).
      RETURN.
    ENDIF.

    DATA(container) = CAST yif_axage_openable( object ).
    container->details( engine->player->location ).
    IF NOT container->is_open( ).
      success( lv_msg ).
      RETURN.
    ENDIF.

    APPEND lv_msg TO lt_msg.
    LOOP AT container->get_content( )->get_list( ) INTO DATA(content).
      engine->player->location->add( content ).
      APPEND content->describe( ) TO lt_msg.
    ENDLOOP.

    success( |You look at details of { object->name }:\n{
                concat_lines_of( table = lt_msg sep = |\n| ) }| ).
  ENDMETHOD.

ENDCLASS.
