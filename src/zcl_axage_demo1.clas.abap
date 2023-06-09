CLASS zcl_axage_demo1 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    METHODS constructor.
  PROTECTED SECTION.
  PRIVATE SECTION.
    DATA bill_developer TYPE REF TO zcl_axage_actor.
    DATA mark_consultant TYPE REF TO zcl_axage_actor.
    DATA engine TYPE REF TO zcl_axage_engine.
    METHODS interprete
      IMPORTING
        command       TYPE clike
      RETURNING
        VALUE(result) TYPE REF TO zcl_axage_result.
ENDCLASS.



CLASS ZCL_AXAGE_DEMO1 IMPLEMENTATION.
  METHOD constructor.
    DATA(repository) = NEW zcl_axage_repository( ).
    engine = NEW #( repository ).
    DATA(entrance)   = engine->new_room( name = 'Entrance' descr = 'You are in the entrance area. Welcome.' ).
    DATA(developer)  = engine->new_room( name = 'Developers office' descr = 'The developers area. be quiet!' ).
    DATA(consulting) = engine->new_room( name = 'Consulting Department' descr = 'This is the area where the consultants work. Bring coffee!' ).

    engine->map->add_room( entrance ).
    engine->map->add_room( developer ).
    engine->map->add_room( consulting ).
    engine->map->set_floor_plan( VALUE #(
      ( `+--------------------+ +--------------------+` )
      ( `|                    | |                    |` )
      ( `|                    | |                    |` )
      ( `|                    +-+                    |` )
      ( `|     ENTRANCE              DEVELOPERS      |` )
      ( `|                    +-+                    |` )
      ( `|                    | |                    |` )
      ( `|                    | |                    |` )
      ( `+--------+  +--------+ +--------------------+` )
      ( `         |  |` )
      ( `+--------+  +--------+` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|   CONSULTANTS      |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `|                    |` )
      ( `+--------------------+` ) ) ).

    entrance->set_exits(
      e = developer
      s = consulting ).
    developer->set_exits(
      w = entrance ).
    consulting->set_exits(
      n = entrance ).
    DATA(cutter_knife) = engine->new_object( name = 'KNIFE' descr = 'a very sharp cutter knife' ).
    developer->add( cutter_knife ).
    DATA(needed_to_open_box) = engine->new_node( 'BoxOpener' ).
    needed_to_open_box->add( cutter_knife ).
    DATA(content_of_box) = engine->new_node( 'BoxContent' ).
    content_of_box->add( engine->new_object( name = 'RFC' descr = 'The request for change.' ) ).
    DATA(card_box) = NEW zcl_axage_openable_thing(
      name    = 'BOX'
      descr   = 'a little card box'
      content = content_of_box
      needed  = needed_to_open_box
      engine = engine ).
    consulting->add( card_box ).

    engine->player->set_location( entrance ).

    bill_developer = engine->new_actor( name = 'Bill' descr = 'An ABAP developer' ).
    bill_developer->set_location( developer ).
    bill_developer->add_sentences( VALUE #(
      ( |Hey, I am Bill, an experienced ABAP developer.| )
      ( |If you have programming tasks for me, you can pass the requirement to me| ) ) ).

    mark_consultant = engine->new_actor( name = 'Mark' descr = 'An SAP consultant' ).
    mark_consultant->set_location( consulting ).
    mark_consultant->add_sentences( VALUE #(
      ( |Hello, My name is Mark and I am an SAP consultant| )
      ( |You can ask me anything about SAP processes.| ) ) ).

    engine->actor_node->add( bill_developer ).
    engine->actor_node->add( mark_consultant ).
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.

    "Add Your Commands Here:
    out->write( interprete( 'HELP'  )->get(  ) ).
    out->write( interprete( 'NORTH'  )->get(  ) ).
    out->write( interprete( 'EAST'  )->get(  ) ).
    out->write( interprete( 'TAKE KNIFE' )->get(  ) ).

    IF engine->player->location->exists( 'RFC' ).
      engine->mission_completed = abap_true.
      out->write( 'Congratulations! You delivered the RFC to the developers!' ).
    ENDIF.
  ENDMETHOD.


  METHOD interprete.
    result = engine->interprete( command ).
    result->add( |You are in the { engine->player->location->name }.| ).
    engine->get_inventory( result ).
  ENDMETHOD.
ENDCLASS.
