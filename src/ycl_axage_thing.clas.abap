CLASS ycl_axage_thing DEFINITION INHERITING FROM ycl_axage
  PUBLIC
  CREATE PROTECTED GLOBAL FRIENDS ycl_axage_engine.

  PUBLIC SECTION.
    INTERFACES if_serializable_object.

    TYPES tt_things TYPE STANDARD TABLE OF REF TO ycl_axage_thing WITH EMPTY KEY.
    DATA index TYPE tv_index.

    DATA name TYPE string.
    DATA description TYPE string.
    DATA prefix TYPE string.
    DATA state TYPE string.
    DATA background TYPE string.

    DATA subject_to TYPE tt_action.
    DATA object_of TYPE tt_action.
    DATA capable_of TYPE tt_action.

    DATA repository TYPE REF TO ycl_axage_repository READ-ONLY.
    DATA index_list TYPE tt_index.


    CLASS-METHODS create_node
      IMPORTING
        name  TYPE clike
        descr TYPE clike OPTIONAL
        repository TYPE REF TO ycl_axage_repository
        prefix TYPE string
      RETURNING VALUE(ro_thing) TYPE REF TO ycl_axage_thing.

    CLASS-METHODS new
      IMPORTING
        type TYPE tv_type DEFAULT c_type_thing
        repository TYPE REF TO ycl_axage_repository
        name  TYPE clike
        descr TYPE clike
        state TYPE clike OPTIONAL
        prefix TYPE string DEFAULT c_prefix
         can_be_pickup TYPE abap_bool DEFAULT abap_true
         can_be_drop TYPE abap_bool DEFAULT  abap_true
         can_be_weld TYPE abap_bool DEFAULT abap_false
         can_be_open TYPE abap_bool DEFAULT abap_false
         can_be_splashed_on TYPE abap_bool DEFAULT abap_false
         can_be_dunked_into TYPE abap_bool DEFAULT abap_false

         can_be_dunked TYPE abap_bool DEFAULT abap_true
         can_be_splashed TYPE abap_bool DEFAULT abap_true
         can_weld TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_thing) TYPE REF TO ycl_axage_thing.

    METHODS constructor
      IMPORTING
        type TYPE tv_type DEFAULT c_type_thing
        repository TYPE REF TO ycl_axage_repository
        name  TYPE clike
        descr TYPE clike
        state TYPE clike
        prefix TYPE string
        background TYPE string DEFAULT space
         can_be_pickup TYPE abap_bool DEFAULT abap_true
         can_be_drop TYPE abap_bool DEFAULT  abap_true
         can_be_weld TYPE abap_bool DEFAULT abap_false
         can_be_open TYPE abap_bool DEFAULT abap_false
         can_be_splashed_on TYPE abap_bool DEFAULT abap_false
         can_be_dunked_into TYPE abap_bool DEFAULT abap_false

         can_be_dunked TYPE abap_bool
         can_be_splashed TYPE abap_bool
         can_weld TYPE abap_bool DEFAULT abap_false.

    METHODS attributes
      IMPORTING
         can_be_pickup TYPE abap_bool
         can_be_drop TYPE abap_bool
         can_be_weld TYPE abap_bool
         can_be_open TYPE abap_bool
         can_be_splashed_on TYPE abap_bool
         can_be_dunked_into TYPE abap_bool

         can_be_dunked TYPE abap_bool
         can_be_splashed TYPE abap_bool
         can_weld TYPE abap_bool.

    METHODS describe IMPORTING with_state TYPE abap_bool DEFAULT abap_true
                     RETURNING VALUE(text) TYPE string.

    METHODS get_list
      IMPORTING include_nodes TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(things) TYPE tt_things.

    METHODS get_by_name
      IMPORTING !name        TYPE clike
      RETURNING VALUE(thing) TYPE REF TO ycl_axage_thing.

    METHODS at_index
      IMPORTING index        TYPE tv_index
      RETURNING VALUE(thing) TYPE REF TO ycl_axage_thing.

    CLASS-METHODS merge_index IMPORTING it_list TYPE tt_index_list
                              RETURNING VALUE(rt_list) TYPE tt_index.
    METHODS get_by_index
      IMPORTING index        TYPE tv_index
      RETURNING VALUE(thing) TYPE REF TO ycl_axage_thing.

    METHODS add
      IMPORTING thing         TYPE REF TO ycl_axage_thing
      RETURNING VALUE(result) TYPE tv_index.

    METHODS delete_by_name
      IMPORTING !name TYPE clike.

    METHODS delete_by_index
      IMPORTING index TYPE tv_index.

    METHODS exists
      IMPORTING !name         TYPE clike
      RETURNING VALUE(exists) TYPE abap_bool.

  PROTECTED SECTION.
    DATA type TYPE tv_type.
  PRIVATE SECTION.
ENDCLASS.



CLASS YCL_AXAGE_THING IMPLEMENTATION.


  METHOD add.
    INSERT thing->index INTO TABLE index_list.
  ENDMETHOD.


  METHOD attributes.
    " Subject to
    INSERT c_action_look INTO TABLE subject_to.  " can always look if not dark

    IF can_be_pickup EQ abap_true.
      INSERT c_action_pickup INTO TABLE subject_to.
    ENDIF.
    IF can_be_drop EQ abap_true.
      INSERT c_action_drop INTO TABLE subject_to.
    ENDIF.
    IF can_be_open EQ abap_true.
      INSERT c_action_open INTO TABLE subject_to.
    ENDIF.
    IF can_be_weld EQ abap_true.
      INSERT c_action_weld INTO TABLE subject_to.
    ENDIF.

    IF can_be_splashed_on EQ abap_true.
      INSERT c_action_splash INTO TABLE subject_to.
    ENDIF.
    IF can_be_dunked_into EQ abap_true.
      INSERT c_action_dunk INTO TABLE subject_to.
    ENDIF.
    " Object of
    IF can_be_dunked EQ abap_true.
      INSERT c_action_dunk INTO TABLE object_of.
    ENDIF.
    IF can_be_splashed EQ abap_true.
      INSERT c_action_splash INTO TABLE object_of.
    ENDIF.

    " Capable of
    IF can_weld EQ abap_true.
      INSERT c_action_weld INTO TABLE capable_of.
    ENDIF.
  ENDMETHOD.


  METHOD at_index.
    thing = repository->at_index( index ).
  ENDMETHOD.


  METHOD constructor.
    super->constructor( ).
    me->type = type.
    me->name = name.
    description = descr.
    me->state = state.
    me->prefix = prefix.
    me->background = background.

    attributes( can_be_pickup      = can_be_pickup
                can_be_drop        = can_be_drop
                can_be_weld        = can_be_weld
                can_be_open        = can_be_open
                can_be_splashed_on   = can_be_splashed_on
                can_be_dunked_into   = can_be_dunked_into

                can_be_dunked      = can_be_dunked
                can_be_splashed    = can_be_splashed
                can_weld           = can_weld ).

    me->repository = repository.

    index = repository->add( me ).
  ENDMETHOD.


  METHOD create_node.
    ro_thing = new( type = c_type_node
                    name = name
                    descr = descr
                    repository = repository
                    prefix = prefix ).
  ENDMETHOD.


  METHOD delete_by_index.
    DELETE index_list WHERE table_line = index.
  ENDMETHOD.


  METHOD delete_by_name.
    DATA(name_uppercase) = to_upper( name ).
    LOOP AT repository->all_things INTO DATA(thing) WHERE table_line->name = name_uppercase.
      DELETE index_list WHERE table_line = thing->index.
      IF sy-subrc EQ 0.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD describe.
    text = prefix && name.
    IF description IS NOT INITIAL.
      text = text && | { description }|.
    ENDIF.
    IF with_state = abap_true AND state IS NOT INITIAL.
      text = text && |, { state }|.
    ENDIF.
  ENDMETHOD.


  METHOD exists.
    exists = abap_false.
    DATA(name_uppercase) = to_upper( name ).
    LOOP AT repository->all_things INTO DATA(thing) WHERE table_line->name = name_uppercase.
      IF line_exists( index_list[ table_line = thing->index ] ).
        exists = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_by_index.
    IF line_exists( index_list[ table_line = index ] ).
      thing = VALUE #( repository->all_things[ index ] OPTIONAL ).
    ENDIF.
  ENDMETHOD.


  METHOD get_by_name.
    DATA(name_uppercase) = to_upper( name ).
    LOOP AT repository->all_things INTO thing WHERE table_line->name = name_uppercase.
      IF line_exists( index_list[ table_line = thing->index ] ).
        RETURN.
      ENDIF.
    ENDLOOP.
    CLEAR thing.
  ENDMETHOD.


  METHOD get_list.
    LOOP AT index_list into DATA(idx).
      DATA(thing) = repository->all_things[ idx ].
      IF include_nodes = abap_true OR thing->type <> c_type_node.
        APPEND thing TO things.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD merge_index.
    rt_list = VALUE #( it_list[ 1 ] OPTIONAL ).
    LOOP AT it_list INTO DATA(list) FROM 2.
      LOOP AT list INTO DATA(idx).
        INSERT idx INTO TABLE rt_list.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.


  METHOD new.
    ro_thing = NEW YCL_AXAGE_THING(
                       type = type
                       repository = repository
                       name = name
                       descr = descr
                       state = state
                       prefix = prefix

                       can_be_pickup = can_be_pickup
                       can_be_drop = can_be_drop
                       can_be_weld = can_be_weld
                       can_be_open = can_be_open
                       can_be_splashed_on = can_be_splashed_on
                       can_be_dunked_into = can_be_dunked_into

                       can_be_dunked = can_be_dunked
                       can_be_splashed = can_be_splashed
                       can_weld = can_weld ).
  ENDMETHOD.
ENDCLASS.
