CLASS ycl_axage_castable_spell DEFINITION
  INHERITING FROM ycl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_axage_command.

    ALIASES execute FOR yif_axage_command~execute.

    METHODS constructor
      IMPORTING !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike     OPTIONAL
                prefix             TYPE string    DEFAULT ycl_axage=>c_prefix
                repository         TYPE REF TO ycl_axage_repository
                can_be_pickup      TYPE abap_bool DEFAULT abap_true
                can_be_drop        TYPE abap_bool DEFAULT abap_true
                can_weld           TYPE abap_bool DEFAULT abap_false
                can_be_weld        TYPE abap_bool DEFAULT abap_false
                can_be_open        TYPE abap_bool DEFAULT abap_false
                can_be_splashed_on TYPE abap_bool DEFAULT abap_false
                can_be_dunked_into TYPE abap_bool DEFAULT abap_false.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS YCL_AXAGE_CASTABLE_SPELL IMPLEMENTATION.

  METHOD constructor.
    super->constructor(
      name  = name
      descr = descr
      state = state
      prefix = prefix
         can_be_pickup = can_be_pickup
         can_be_drop = can_be_drop
         can_weld = can_weld
         can_be_weld = can_be_weld
         can_be_open = abap_true
         can_be_splashed_on = can_be_splashed_on
         can_be_dunked_into = can_be_dunked_into
         can_be_dunked = abap_false
         can_be_splashed = abap_false
         repository = repository ).
    yif_axage_command~category = yif_axage_command=>c_spell.
  ENDMETHOD.


  METHOD execute.

    IF yif_axage_command~category NE yif_axage_command=>c_spell.
      log->error_msg( title = |CAST { name }|
                      subtitle = ''
                      description = |{ name } is not a spell.| ).
      RETURN.
    ENDIF.

    DATA(player) = engine->player.

    CASE name.
      WHEN 'LUMI'.
        DATA(location) = player->location.
        IF location->dark = abap_true.
          location->dark = abap_false.
          location->state = 'illuminated'.
          log->success_msg( title = 'CAST LUMI'
                            subtitle = |You cast the spell { me->describe( ) }|
                            description = |{ location->describe( ) }.| ).
        ELSE.
          log->info_msg( title = 'CAST LUMI'
                         subtitle = |The space has already light|
                         description = |{ location->describe( ) }.| ).
        ENDIF.
      WHEN 'PORTA'.
        IF player->exists( 'MOONSTAFF' ).
          engine->mission_completed = abap_true.
          log->success_msg( title = 'CAST PORTA'
                            subtitle = |You cast the spell { me->describe( ) }|
                            description = |You go through a portal to the Wizard's Guild.| ).
        ELSE.
          log->error_msg( title = 'CAST PORTA'
                          subtitle = |You cast the spell { me->describe( ) }|
                          description = |You can only cast "Portallis" by using the Staff of Eternal Moon| ).
        ENDIF.

      WHEN OTHERS.
        log->error_msg( title = |CAST { name }|
                        subtitle = |SPELL { name }|
                        description = |This { name } spell has no use.| ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
