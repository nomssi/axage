CLASS zcl_axage_action DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS execute ABSTRACT.
    METHODS constructor IMPORTING objects TYPE string_table
                                  player  TYPE REF TO zcl_axage_actor
                                  actor_node  TYPE REF TO zcl_axage_thing
                                  engine TYPE REF TO zcl_axage_engine
                                  !result TYPE REF TO zcl_axage_result
                                  operation TYPE string.
    CLASS-METHODS new IMPORTING engine TYPE REF TO zcl_axage_engine
                                !action         TYPE clike
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

    DATA param1 TYPE string.
    DATA owned_things TYPE zcl_axage_thing=>tt_index.
    DATA available_things TYPE zcl_axage_thing=>tt_index.
    DATA repository TYPE REF TO zcl_axage_repository.

    METHODS validate IMPORTING into_object  TYPE string
                               operation    TYPE string
                               it_from      TYPE zcl_axage_thing=>tt_index
                     EXPORTING eo_item      TYPE REF TO zcl_axage_thing
                     RETURNING VALUE(valid) TYPE abap_bool.
    METHODS mandatory_params IMPORTING number TYPE i
                             RETURNING VALUE(valid) TYPE abap_bool.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_axage_action IMPLEMENTATION.

  METHOD mandatory_params.
    DATA(count) = lines( objects ).
    valid = abap_true.
    IF count IS INITIAL and number GT 0.
      valid = abap_false.
      result->error_msg( title = |missing object in { operation }|
                         subtitle = operation
                         description = |{ operation } what?| ).
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
    param1 = VALUE #( objects[ 1 ] OPTIONAL ).
  ENDMETHOD.

  METHOD validate.
    FIELD-SYMBOLS <flag> TYPE abap_bool.

    valid = abap_false.
    CLEAR eo_item.
    IF mandatory_params( 1 ).
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
          result->error_msg( title = |{ operation } { into_object }|
                             subtitle = player->location->name
                             description = |{ operation } is not allowed for a { into_object }| ).
        ELSE.
          valid = abap_true.
        ENDIF.
      ELSEIF from IS BOUND AND from->get_list( ) IS INITIAL.
        result->error_msg( title = |{ operation } { into_object }|
                           subtitle = player->location->name
                           description = |You cannot find { into_object } for { operation }...| ).
      ELSE.
        result->error_msg( title = |{ operation } { into_object }|
                           subtitle = player->location->name
                           description = |There is no { into_object } you can { operation }| ).
      ENDIF.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
