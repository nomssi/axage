CLASS ycl_axage_action DEFINITION
  PUBLIC ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS c_similarity_level TYPE i VALUE 70.  " 70% similarity
    TYPES tt_thing TYPE STANDARD TABLE OF REF TO ycl_axage_thing WITH EMPTY KEY.

    METHODS execute  ABSTRACT
      RETURNING VALUE(processed) TYPE abap_bool.

    CLASS-METHODS best_match
      IMPORTING token        TYPE string
                valid_tokens TYPE string_table
                !percentage  TYPE i DEFAULT c_similarity_level
      RETURNING VALUE(variant)   TYPE string.

    CLASS-METHODS propose_command
      IMPORTING token            TYPE string
                allowed_commands TYPE ycl_axage=>tt_command
      RETURNING VALUE(variant)   TYPE string.

    CLASS-METHODS propose_parameter
      IMPORTING token          TYPE string
                it_index       TYPE ycl_axage=>tt_index
                repository     TYPE REF TO ycl_axage_repository
      RETURNING VALUE(variant) TYPE string.

    CLASS-METHODS process IMPORTING !action          TYPE ycl_axage=>tv_action
                                    allowed_commands TYPE ycl_axage=>tt_command
                                    params           TYPE string_table
                                    engine           TYPE REF TO ycl_axage_engine
                                    !log             TYPE REF TO ycl_axage_log
                          RETURNING VALUE(executed)  TYPE abap_bool.

    METHODS constructor IMPORTING !objects  TYPE string_table
                                  engine    TYPE REF TO ycl_axage_engine
                                  !log      TYPE REF TO ycl_axage_log
                                  operation TYPE string.

    METHODS info
      IMPORTING !description TYPE string.

    METHODS warning
      IMPORTING !description TYPE string.

    METHODS success
      IMPORTING !description TYPE string.

    METHODS error
      IMPORTING !description TYPE string.

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

  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_AXAGE_ACTION IMPLEMENTATION.


  METHOD constructor.
    me->operation = to_upper( operation ).
    me->objects = objects.
    me->log = log.
    me->engine = engine.
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
          executed = lo_action->execute( ).
        ENDIF.
        " cx_sy_create_object_error.
      CATCH cx_root INTO DATA(lx_error).
        log->add( lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD best_match.
    TYPES: BEGIN OF distance,
             text TYPE string,
             dist TYPE i,
           END OF distance.
    DATA distances TYPE SORTED TABLE OF distance WITH NON-UNIQUE KEY dist.

    variant = space.
    DATA(len_token) = strlen( token ).
    " search Minimum
    LOOP AT valid_tokens ASSIGNING FIELD-SYMBOL(<token>).
      DATA(len_action) = strlen( <token> ).
      DATA(max) = COND i( WHEN len_action > len_token
                          THEN len_action
                          ELSE len_token ).
      max = ( 100 - percentage ) * max / 100 + 1.

      DATA(dist) = distance( val1 = <token>
                             val2 = token
                             max = max ).
      IF dist < max.
        distances = VALUE #( BASE distances
                            ( text = <token> dist = dist ) ).
      ENDIF.
    ENDLOOP.
    variant = VALUE #( distances[ 1 ]-text OPTIONAL ).
  ENDMETHOD.

  METHOD propose_command.

    DATA(lt_allowed) = VALUE string_table( FOR <command> IN allowed_commands ( <command>-action ) ).
    variant = best_match( token = token
                          valid_tokens = lt_allowed
                          percentage = c_similarity_level ).
  ENDMETHOD.

  METHOD propose_parameter.
    DATA lt_params TYPE string_table.

    LOOP AT it_index INTO DATA(from_idx).
      DATA(lo_from) = repository->by_index( from_idx ).
      IF lo_from IS BOUND.
        APPEND lo_from->name TO lt_params.
      ENDIF.
    ENDLOOP.

    variant = best_match( token = token
                          valid_tokens = lt_params
                          percentage = c_similarity_level ).
  ENDMETHOD.

  METHOD validate.
    DATA text    TYPE string.
    DATA lo_item TYPE REF TO ycl_axage_thing.
    DATA lo_from TYPE REF TO ycl_axage_thing.

    valid = abap_false.
    CLEAR et_item.
    IF NOT mandatory_params( number_of_parameters ).
      RETURN.
    ENDIF.

    DATA(title) = operation.
    DATA(location_name) = engine->player->location->name.

    LOOP AT objects INTO DATA(apply_to_object).
      CLEAR text.
      lo_item = engine->by_name( EXPORTING name = apply_to_object
                                           it_index = it_from
                                 IMPORTING from = lo_from ).
      IF lo_item IS NOT BOUND.
        IF lo_from IS BOUND AND lo_from->get_list( ) IS INITIAL.
          text = |{ operation } is not applicable to { apply_to_object } right now...|.
        ELSE.
          text = |There is no { apply_to_object } you can { operation }|.
        ENDIF.

        DATA(variant) = propose_parameter( repository = engine
                                           it_index = it_from
                                           token = apply_to_object ).
        IF variant IS NOT INITIAL.
          text = text && |. Did you possibly mean { variant }?|.
        ENDIF.

      ELSE.

        IF    line_exists( lo_item->subject_to[ table_line = operation ] )
           OR line_exists( lo_item->object_of[ table_line = operation ] )
           OR lo_item IS INSTANCE OF yif_axage_command.
          valid = abap_true.
          INSERT lo_item INTO TABLE et_item.
          title = title && | { apply_to_object }|.
        ELSE.
          text = |{ operation } is not allowed for a { apply_to_object }|.
        ENDIF.

      ENDIF.

      IF text IS NOT INITIAL.
        log->error_msg( title = title && | { apply_to_object }|
                        subtitle = location_name
                        description = text ).
        DELETE objects.  " future success message should not contains error parameter
      ENDIF.

    ENDLOOP.
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

  METHOD success.
    log->success_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                      subtitle = engine->player->location->name
                      description = description ).
  ENDMETHOD.

  METHOD warning.
    log->warning_msg( title = |{ operation } { concat_lines_of( table = objects sep = ` ` ) }|
                      subtitle = engine->player->location->name
                      description = description ).
  ENDMETHOD.
ENDCLASS.
