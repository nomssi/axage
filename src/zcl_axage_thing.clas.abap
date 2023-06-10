CLASS zcl_axage_thing DEFINITION
  PUBLIC
  CREATE PROTECTED GLOBAL FRIENDS zcl_axage_engine.

  PUBLIC SECTION.
    TYPES tv_type TYPE c LENGTH 6.
    TYPES tv_index TYPE i.
    TYPES tt_things TYPE STANDARD TABLE OF REF TO zcl_axage_thing WITH EMPTY KEY.
    TYPES tt_index TYPE SORTED TABLE OF tv_index WITH UNIQUE DEFAULT KEY.
    TYPES tt_index_list TYPE STANDARD TABLE OF tt_index.

    CONSTANTS c_prefix TYPE string VALUE `a `.
    CONSTANTS c_type_node TYPE tv_type VALUE 'node'.

    CONSTANTS c_type_thing TYPE tv_type VALUE 'thing'.
    CONSTANTS c_type_actor TYPE tv_type VALUE 'actor'.
    CONSTANTS c_type_room TYPE tv_type VALUE 'room'.
    CONSTANTS c_type_no_exit TYPE tv_type VALUE 'noexit'.

    INTERFACES if_serializable_object.

    DATA index TYPE tv_index.

    DATA name TYPE string.
    DATA description TYPE string.
    DATA prefix TYPE string.
    DATA state TYPE string.

    DATA can_be_pickup TYPE abap_bool READ-ONLY.
    DATA can_weld TYPE abap_bool READ-ONLY.
    DATA can_be_weld TYPE abap_bool READ-ONLY.
    DATA can_be_drop TYPE abap_bool READ-ONLY.
    DATA can_be_open TYPE abap_bool READ-ONLY.
    DATA can_be_splash_into TYPE abap_bool READ-ONLY.
    DATA can_be_dunk_into TYPE abap_bool READ-ONLY.

    DATA repository TYPE REF TO zcl_axage_repository READ-ONLY.
    DATA index_list TYPE tt_index.


    CLASS-METHODS create_node
      IMPORTING
        name  TYPE clike
        descr TYPE clike OPTIONAL
        repository TYPE REF TO zcl_axage_repository
        prefix TYPE string
      RETURNING VALUE(ro_thing) TYPE REF TO zcl_axage_thing.

    CLASS-METHODS new
      IMPORTING
        type TYPE tv_type DEFAULT c_type_thing
        repository TYPE REF TO zcl_axage_repository
        name  TYPE clike
        descr TYPE clike
        state TYPE clike OPTIONAL
        prefix TYPE string DEFAULT c_prefix
         can_be_pickup TYPE abap_bool DEFAULT abap_true
         can_be_drop TYPE abap_bool DEFAULT  abap_true
         can_weld TYPE abap_bool DEFAULT abap_false
         can_be_weld TYPE abap_bool DEFAULT abap_false
         can_be_open TYPE abap_bool DEFAULT abap_false
         can_be_splash_into TYPE abap_bool DEFAULT abap_false
         can_be_dunk_into TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(ro_thing) TYPE REF TO zcl_axage_thing.

    METHODS constructor
      IMPORTING
        type TYPE tv_type DEFAULT c_type_thing
        repository TYPE REF TO zcl_axage_repository
        name  TYPE clike
        descr TYPE clike
        state TYPE clike
        prefix TYPE string
         can_be_pickup TYPE abap_bool DEFAULT abap_true
         can_be_drop TYPE abap_bool DEFAULT  abap_true
         can_weld TYPE abap_bool DEFAULT abap_false
         can_be_weld TYPE abap_bool DEFAULT abap_false
         can_be_open TYPE abap_bool DEFAULT abap_false
         can_be_splash_into TYPE abap_bool DEFAULT abap_false
         can_be_dunk_into TYPE abap_bool DEFAULT abap_false
         first TYPE tv_index DEFAULT 1
         rest TYPE tv_index DEFAULT 1.

    METHODS describe IMPORTING with_state TYPE abap_bool DEFAULT abap_true
                     RETURNING VALUE(text) TYPE string.

    METHODS get_list
      IMPORTING include_nodes TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(things) TYPE tt_things.

    METHODS get_by_name
      IMPORTING !name        TYPE clike
      RETURNING VALUE(thing) TYPE REF TO zcl_axage_thing.

    METHODS at_index
      IMPORTING index        TYPE tv_index
      RETURNING VALUE(thing) TYPE REF TO zcl_axage_thing.

    CLASS-METHODS merge_index IMPORTING it_list TYPE tt_index_list
                              RETURNING VALUE(rt_list) TYPE tt_index.
    METHODS get_by_index
      IMPORTING index        TYPE tv_index
      RETURNING VALUE(thing) TYPE REF TO zcl_axage_thing.

    METHODS show
      RETURNING VALUE(result) TYPE string_table.

    METHODS add
      IMPORTING thing         TYPE REF TO zcl_axage_thing
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



CLASS ZCL_AXAGE_THING IMPLEMENTATION.

  METHOD add.
    INSERT thing->index INTO TABLE index_list.
  ENDMETHOD.

  METHOD at_index.
    thing = repository->at_index( index ).
  ENDMETHOD.

  METHOD constructor.
    me->type = type.
    me->name = name.
    description = descr.
    me->state              = state.
    me->prefix             = prefix.

    me->can_be_pickup      = can_be_pickup.
    me->can_be_drop        = can_be_drop.

    me->can_weld           = can_weld.
    me->can_be_weld        = can_be_weld.
    me->can_be_open        = can_be_open.
    me->can_be_splash_into = can_be_splash_into.
    me->can_be_dunk_into   = can_be_dunk_into.
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

  METHOD delete_by_index.
    DELETE index_list WHERE table_line = index.
  ENDMETHOD.

  METHOD get_by_index.
    IF line_exists( index_list[ table_line = index ] ).
      thing = VALUE #( repository->all_things[ index ] OPTIONAL ).
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

  METHOD get_by_name.
    DATA(name_uppercase) = to_upper( name ).
    LOOP AT repository->all_things INTO thing WHERE table_line->name = name_uppercase.
      IF line_exists( index_list[ table_line = thing->index ] ).
        RETURN.
      ENDIF.
    ENDLOOP.
    CLEAR thing.
  ENDMETHOD.


  METHOD GET_LIST.
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
    ro_thing = NEW ZCL_AXAGE_THING(
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
                       can_be_splash_into = can_be_splash_into
                       can_be_dunk_into = can_be_dunk_into ).
  ENDMETHOD.


  METHOD show.
    LOOP AT index_list into DATA(idx).
      DATA(thing) = repository->all_things[ idx ].
      CHECK thing->type <> c_type_node.
      APPEND thing->describe( ) TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
