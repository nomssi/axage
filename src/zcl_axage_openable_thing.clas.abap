CLASS zcl_axage_openable_thing DEFINITION
  INHERITING FROM zcl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_axage_openable.

    ALIASES open        FOR zif_axage_openable~open.
    ALIASES details     FOR zif_axage_openable~details.
    ALIASES get_content FOR zif_axage_openable~get_content.
    ALIASES is_open     FOR zif_axage_openable~is_open.

    METHODS constructor
      IMPORTING !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike     OPTIONAL
                needed             TYPE REF TO zcl_axage_thing
                content            TYPE REF TO zcl_axage_thing
                engine             TYPE REF TO zcl_axage_engine
                can_be_pickup      TYPE abap_bool DEFAULT abap_true
                can_be_drop        TYPE abap_bool DEFAULT  abap_true
                can_weld           TYPE abap_bool DEFAULT abap_false
                can_be_weld        TYPE abap_bool DEFAULT abap_false
                can_be_open        TYPE abap_bool DEFAULT abap_false
                can_be_splash_into TYPE abap_bool DEFAULT abap_false
                can_be_dunk_into   TYPE abap_bool DEFAULT abap_false.

    DATA needed TYPE REF TO zcl_axage_thing.

  PROTECTED SECTION.
    DATA opened TYPE abap_bool.
    DATA content TYPE REF TO zcl_axage_thing.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AXAGE_OPENABLE_THING IMPLEMENTATION.


  METHOD constructor.
    super->constructor(
      name  = name
      descr = descr
      state = state
         can_be_pickup = can_be_pickup
         can_be_drop = can_be_drop
         can_weld = can_weld
         can_be_weld = can_be_weld
         can_be_open = can_be_open
         can_be_splash_into = can_be_splash_into
         can_be_dunk_into = can_be_dunk_into
         engine = engine ).
    me->needed = needed.
    me->content = content.
  ENDMETHOD.


  METHOD get_content.
    IF opened = abap_true.
      content = me->content.
    ENDIF.
  ENDMETHOD.


  METHOD is_open.
    result = opened.
  ENDMETHOD.


  METHOD open.
    result = NEW #( ).
    data allowed type abap_Bool.

    LOOP AT needed->get_list( ) INTO DATA(open_with).
      IF things->exists( open_with->name ).
        allowed = abap_true.
        result->add( |The { name } is now open| ).
        me->opened = abap_true.
        EXIT. "from loop
      ENDIF.
    ENDLOOP.

    IF allowed = abap_false.
      result->add( |You have nothing the { name } can be opened with!| ).
    ENDIF.

    opened = me->opened.
  ENDMETHOD.

  METHOD details.
    IF needed->get_list( ) IS INITIAL AND location->dark EQ abap_false.
       me->opened = abap_true.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
