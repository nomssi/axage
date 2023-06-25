CLASS ycl_axage_openable_thing DEFINITION
  INHERITING FROM ycl_axage_thing
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES yif_axage_openable.

    ALIASES open        FOR yif_axage_openable~open.
    ALIASES details     FOR yif_axage_openable~details.
    ALIASES get_content FOR yif_axage_openable~get_content.
    ALIASES is_open     FOR yif_axage_openable~is_open.

    METHODS constructor
      IMPORTING !name              TYPE clike
                descr              TYPE clike
                !state             TYPE clike     OPTIONAL
                prefix             TYPE string DEFAULT ycl_axage=>c_prefix
                needed             TYPE REF TO ycl_axage_thing
                content            TYPE REF TO ycl_axage_thing
                repository         TYPE REF TO ycl_axage_repository
                can_be_pickup      TYPE abap_bool DEFAULT abap_true
                can_be_drop        TYPE abap_bool DEFAULT  abap_true
                can_weld           TYPE abap_bool DEFAULT abap_false
                can_be_weld        TYPE abap_bool DEFAULT abap_false
                can_be_open        TYPE abap_bool DEFAULT abap_false
                can_be_splashed    TYPE abap_bool DEFAULT abap_false
                can_be_splashed_on TYPE abap_bool DEFAULT abap_false
                can_be_dunked      TYPE abap_bool DEFAULT abap_false
                can_be_dunked_into TYPE abap_bool DEFAULT abap_false.

    DATA needed TYPE REF TO ycl_axage_thing.

  PROTECTED SECTION.
    DATA opened  TYPE abap_bool.
    DATA content TYPE REF TO ycl_axage_thing.

  PRIVATE SECTION.
ENDCLASS.

CLASS ycl_axage_openable_thing IMPLEMENTATION.


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
         can_be_splashed = can_be_splashed
         can_be_splashed_on = can_be_splashed_on
         can_be_dunked = can_be_dunked
         can_be_dunked_into = can_be_dunked_into
         repository = repository ).
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

  METHOD details.
    DATA(dark) = abap_false.
    IF location IS INSTANCE OF ycl_axage_room
      AND CAST ycl_axage_room( location )->dark = abap_true.
      dark = abap_true.
    ENDIF.

    IF needed->get_list( ) IS INITIAL AND dark EQ abap_false.
      me->opened = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD open.
    data allowed type abap_Bool.

    LOOP AT needed->get_list( ) INTO DATA(open_with).
      IF things->exists( open_with->name ).
        allowed = abap_true.
        me->state = |You use the { open_with->name } to open the { name }|.
        log->add( me->state ).
        me->opened = abap_true.
        EXIT. "from loop
      ENDIF.
    ENDLOOP.

    IF allowed = abap_false.
      log->add( |You cannot open { name } like this.| ).
    ENDIF.

    opened = me->opened.
  ENDMETHOD.
ENDCLASS.
