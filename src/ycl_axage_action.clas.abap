CLASS ycl_axage_action DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES tt_thing TYPE STANDARD TABLE OF REF TO ycl_axage_thing WITH EMPTY KEY.

    METHODS execute ABSTRACT.

    CLASS-METHODS propose_command
      IMPORTING token            TYPE string
                allowed_commands TYPE ycl_axage=>tt_command
                !percentage      TYPE i DEFAULT 70  " 70% similarity
      RETURNING VALUE(variant)   TYPE string.

    CLASS-METHODS process IMPORTING action           TYPE ycl_axage=>tv_action
                                    allowed_commands TYPE ycl_axage=>tt_command
                                    params           TYPE string_table
                                    engine           TYPE REF TO ycl_axage_engine
                                    log              TYPE REF TO ycl_axage_log
                          RETURNING VALUE(executed)  TYPE abap_bool.

    METHODS constructor IMPORTING !objects TYPE string_table
                                  engine TYPE REF TO ycl_axage_engine
                                  !log TYPE REF TO ycl_axage_log
                                  operation TYPE string.

  PROTECTED SECTION.
    DATA operation TYPE string.
    DATA objects TYPE string_table.
    DATA log TYPE REF TO ycl_axage_log.
    DATA engine TYPE REF TO ycl_axage_engine.

    METHODS validate IMPORTING number_of_parameters TYPE i DEFAULT 1
                               it_from      TYPE ycl_axage=>tt_index
                     EXPORTING et_item      TYPE tt_thing
                     RETURNING VALUE(valid) TYPE abap_bool.
    METHODS mandatory_params IMPORTING number TYPE i
                             RETURNING VALUE(valid) TYPE abap_bool.

    METHODS info
      IMPORTING !description TYPE string.
    METHODS warning
      IMPORTING !description TYPE string.
    METHODS success
      IMPORTING !description TYPE string.
    METHODS error
      IMPORTING !description TYPE string.

  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_AXAGE_ACTION IMPLEMENTATION.


  METHOD constructor.
    me->operation = to_upper( operation ).
    me->objects = objects.
    me->log = log.
    me->engine = engine.
  ENDMETHOD.


  METHOD error.
    log->error_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                    subtitle = engine->player->location->name
                    description = description ).
  ENDMETHOD.


  METHOD info.
    log->info_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                   subtitle = engine->player->location->name
                   description = description ).
  ENDMETHOD.


  METHOD mandatory_params.
    DATA(count) = lines( objects ).
    valid = abap_true.
    IF count < number.
      valid = abap_false.
      IF count IS INITIAL.
        DATA(description) = |{ operation } what?|.
      ELSE.
        description = |{ operation } { objects[ 1 ] } to what?|.
      ENDIF.
      error( description = |missing object in { description }|  ).
    ENDIF.
  ENDMETHOD.


  METHOD process.
    DATA lo_action TYPE REF TO ycl_axage_action.

    executed = abap_false.

    IF action IS INITIAL.
      log->add( 'Got your wizard hat on too tight? Try looking around' ).
      RETURN.
    ENDIF.

    DATA(command) = VALUE #( allowed_commands[ action = action ] OPTIONAL ).

    IF command-classname IS INITIAL.

      DATA(variant) = propose_command( allowed_commands = allowed_commands
                                       token = action ).
      IF variant IS INITIAL.
        DATA(msg) = |{ action } is not recognized in this realm.|.
      ELSE.
        msg = |Oops, { action } didn't work. Did you possibly mean to { variant }?|.
      ENDIF.
      log->add( msg ).

      RETURN.
    ENDIF.

    IF command-operation IS INITIAL.
      command-operation = command-action.  " customizing only checked for the canonical operation
    ENDIF.

    TRY.
        CREATE OBJECT lo_action TYPE (command-classname)
          EXPORTING objects = params
                    engine = engine
                    log = log
                    operation = command-operation.

        IF lo_action IS BOUND.
          lo_action->execute( ).
          executed = abap_true.
        ENDIF.
        " cx_sy_create_object_error.
      CATCH cx_root INTO DATA(lx_error).
        log->add( lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD propose_command.
    TYPES: BEGIN OF distance,
             text TYPE string,
             dist TYPE i,
           END OF distance.

    DATA distances TYPE SORTED TABLE OF distance WITH NON-UNIQUE KEY dist.

    variant = space.
    DATA(len_token) = strlen( token ).
    " search Minimum
    LOOP AT allowed_commands ASSIGNING FIELD-SYMBOL(<command>).
      DATA(len_action) = strlen( <command>-action ).
      DATA(max) = COND i( WHEN len_action > len_token
                          THEN len_action
                          ELSE len_token ).
      max = ( 100 - percentage ) * max / 100 + 1.

      DATA(dist) = distance( val1 = <command>-action
                             val2 = token
                             max = max ).
      IF dist < max.
        distances = VALUE #( BASE distances
                            ( text = <command>-action dist = dist ) ).
      ENDIF.
    ENDLOOP.
    variant = VALUE #( distances[ 1 ]-text OPTIONAL ).
  ENDMETHOD.


  METHOD success.
    log->success_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                      subtitle = engine->player->location->name
                      description = description ).
  ENDMETHOD.


  METHOD validate.
    DATA lo_item TYPE REF TO ycl_axage_thing.

    valid = abap_false.
    CLEAR et_item.
    IF NOT mandatory_params( number_of_parameters ).
      RETURN.
    ENDIF.

    DATA(title) = operation.
    DATA(location_name) = engine->player->location->name.

    LOOP AT objects INTO DATA(apply_to_object).
      LOOP AT it_from INTO DATA(from_idx).
        DATA(from) = CAST ycl_axage_repository( engine )->at_index( from_idx ).
        IF from IS BOUND AND from->name = apply_to_object.
          lo_item = from.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lo_item IS BOUND.

        IF    line_exists( lo_item->subject_to[ table_line = operation ] )
           OR lo_item IS INSTANCE OF yif_axage_command.
          valid = abap_true.
          INSERT lo_item INTO TABLE et_item.
          title = title && | { apply_to_object }|.
        ELSE.
          log->error_msg( title = title && | { apply_to_object }|
                          subtitle = location_name
                          description = |{ operation } is not allowed for a { apply_to_object }| ).
        ENDIF.
      ELSEIF from IS BOUND AND from->get_list( ) IS INITIAL.
        log->error_msg( title = title && | { apply_to_object }|
                        subtitle = location_name
                        description = |{ operation } is not applicable to { apply_to_object } right now...| ).
      ELSE.
        log->error_msg( title = title && | { apply_to_object }|
                        subtitle = location_name
                        description = |There is no { apply_to_object } you can { operation }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD warning.
    log->warning_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                      subtitle = engine->player->location->name
                      description = description ).
  ENDMETHOD.
ENDCLASS.
