CLASS zcl_axage_action DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES tt_thing TYPE STANDARD TABLE OF REF TO zcl_axage_thing WITH EMPTY KEY.

    METHODS execute ABSTRACT.
    METHODS constructor IMPORTING objects TYPE string_table
                                  player  TYPE REF TO zcl_axage_actor
                                  actor_node  TYPE REF TO zcl_axage_thing
                                  engine TYPE REF TO zcl_axage_engine
                                  !result TYPE REF TO zcl_axage_result
                                  operation TYPE string.
    CLASS-METHODS new IMPORTING engine TYPE REF TO zcl_axage_engine
                                !action         TYPE zcl_axage=>tv_action
                                 params          TYPE string_table
                                !result         TYPE REF TO zcl_axage_result
                       RETURNING VALUE(ro_action) TYPE REF TO zcl_axage_action
                       RAISING CX_SY_CREATE_OBJECT_ERROR.

  PROTECTED SECTION.
    DATA operation TYPE string.
    DATA objects TYPE string_table.
    DATA player TYPE REF TO zcl_axage_actor.
    DATA actor_node TYPE REF TO zcl_axage_thing.
    DATA result  TYPE REF TO zcl_axage_result.
    DATA engine TYPE REF TO zcl_axage_engine.

    DATA owned_things TYPE zcl_axage=>tt_index.
    DATA available_things TYPE zcl_axage=>tt_index.
    DATA repository TYPE REF TO zcl_axage_repository.

    METHODS validate IMPORTING number_of_parameters TYPE i DEFAULT 1
                               it_from      TYPE zcl_axage=>tt_index
                     EXPORTING et_item      TYPE tt_thing
                     RETURNING VALUE(valid) TYPE abap_bool.
    METHODS mandatory_params IMPORTING number TYPE i
                             RETURNING VALUE(valid) TYPE abap_bool.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_axage_action IMPLEMENTATION.

  METHOD mandatory_params.
    DATA(count) = lines( objects ).
    valid = abap_true.
    IF count < number.
      valid = abap_false.
      IF count IS INITIAL.
        result->error_msg( title = |missing subject in { operation }|
                           subtitle = operation
                           description = |{ operation } what?| ).
       ELSE.
        result->error_msg( title = |missing object in { operation }|
                           subtitle = operation
                           description = |{ operation } { objects[ 1 ] } to what?| ).
       ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD new.
    DATA(command) = VALUE #( engine->allowed_commands[ action = action ] OPTIONAL ).

    IF command-classname IS INITIAL.
      RETURN.
    ENDIF.

    IF command-operation IS INITIAL.
      command-operation = command-action.
    ENDIF.

    CREATE OBJECT ro_action TYPE (command-classname)
      EXPORTING objects = params
                player = engine->player
                actor_node = engine->actor_node
                engine = engine
                result = result
                operation = command-operation.
  ENDMETHOD.

  METHOD constructor.
    me->objects = objects.
    me->player = player.
    me->actor_node = actor_node.
    me->result = result.
    me->engine = engine.
    me->operation = to_upper( operation ).

    owned_things = player->index_list.
    available_things = player->location->index_list.
    repository = engine->repository.
  ENDMETHOD.

  METHOD validate.
    DATA lo_item TYPE REF TO zcl_axage_thing.

    valid = abap_false.
    CLEAR et_item.
    IF NOT mandatory_params( number_of_parameters ).
      RETURN.
    ENDIF.

    DATA(title) = operation.
    LOOP AT objects INTO DATA(apply_to_object).
      LOOP AT it_from INTO DATA(from_idx).
        DATA(from) = repository->at_index( from_idx ).
        IF from IS BOUND AND from->name = apply_to_object.
          lo_item = from.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lo_item IS BOUND.

        IF line_exists( lo_item->subject_to[ table_line = operation ] )
          OR lo_item IS INSTANCE OF zif_axage_command.
          valid = abap_true.
          INSERT lo_item INTO TABLE et_item.
          title = title && | { apply_to_object }|.
        ELSE.
          result->error_msg( title = title && | { apply_to_object }|
                             subtitle = player->location->name
                             description = |{ operation } is not allowed for a { apply_to_object }| ).
        ENDIF.
      ELSEIF from IS BOUND AND from->get_list( ) IS INITIAL.
        result->error_msg( title = title && | { apply_to_object }|
                           subtitle = player->location->name
                           description = |You cannot use { apply_to_object } for { operation }...| ).
      ELSE.
        result->error_msg( title = title && | { apply_to_object }|
                           subtitle = player->location->name
                           description = |There is no { apply_to_object } you can { operation }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
