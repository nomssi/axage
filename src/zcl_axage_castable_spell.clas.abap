CLASS zcl_axage_castable_spell DEFINITION
  INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_axage_command.

    ALIASES execute     FOR zif_axage_command~execute.

    METHODS constructor
      IMPORTING !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike     OPTIONAL
                prefix             TYPE string DEFAULT zcl_axage=>c_prefix
                repository         TYPE REF TO zcl_axage_repository
                can_be_pickup      TYPE abap_bool DEFAULT abap_true
                can_be_drop        TYPE abap_bool DEFAULT  abap_true
                can_weld           TYPE abap_bool DEFAULT abap_false
                can_be_weld        TYPE abap_bool DEFAULT abap_false
                can_be_open        TYPE abap_bool DEFAULT abap_false
                can_be_splash_into TYPE abap_bool DEFAULT abap_false
                can_be_dunk_into   TYPE abap_bool DEFAULT abap_false.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AXAGE_CASTABLE_SPELL IMPLEMENTATION.
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
         can_be_splash_into = can_be_splash_into
         can_be_dunk_into = can_be_dunk_into
         repository = repository ).
    zif_axage_command~category = zif_axage_command=>c_spell.
  ENDMETHOD.


  METHOD execute.
    DATA(player) = engine->player.
    DATA(location) = player->location.

    IF zif_axage_command~category NE zif_axage_command=>c_spell.
      result->add( |{ name } is not a spell.| ).
      RETURN.
    ENDIF.

    result->add( |You cast the spell { me->describe( ) }| ).
    CASE name.
      WHEN 'LUMI'.
        IF player->location->dark = abap_true.
          player->location->dark = abap_false.
          player->location->state = 'illuminated'.
          result->add( |{ location->describe( ) }.| ).
        ENDIF.
      WHEN 'PORT'.
        engine->mission_completed = abap_true.
        result->add( |You go through a portal to the Wizard's Guild.| ).

      WHEN OTHERS.
        result->add( |This { name } spell is useless.| ).

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
