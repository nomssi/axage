CLASS zcl_axage_wizard_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    DATA command          TYPE string.
    DATA auto_look        TYPE abap_bool VALUE abap_true.
    DATA anzahl_items     TYPE string    VALUE '0'.
    DATA results          TYPE string.
    DATA help             TYPE string.
    DATA formatted_text   TYPE string.
    DATA player_name      TYPE string.

    DATA current_location TYPE string.
    DATA cheat_sheet      TYPE string.
    DATA background_image TYPE string.

    TYPES:
      BEGIN OF ts_suggestion_items,
        value TYPE string,
        descr TYPE string,
      END OF ts_suggestion_items.

    DATA mt_suggestion TYPE STANDARD TABLE OF ts_suggestion_items WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_file,
        selkz  TYPE abap_bool,
        name   TYPE string,
        format TYPE string,
        size   TYPE string,
        descr  TYPE string,
        data   TYPE string,
      END OF ty_file.

    DATA mt_file      TYPE STANDARD TABLE OF ty_file WITH EMPTY KEY.
    DATA ms_file_prev TYPE ty_file.

    DATA messages     TYPE ycl_axage_log=>tt_msg.

    METHODS view_popup_input
      IMPORTING !client TYPE REF TO z2ui5_if_client.

  PRIVATE SECTION.
    CONSTANTS c_id_command TYPE string VALUE 'id_command'.

    DATA:
      BEGIN OF app,
        client            TYPE REF TO z2ui5_if_client,
        check_initialized TYPE abap_bool,
        main_view         TYPE string,
        popup_view        TYPE string,
        s_get             TYPE z2ui5_if_client=>ty_s_get,
      END OF app.

    DATA mv_popup_name TYPE string.
    DATA engine        TYPE REF TO ycl_axage_engine.

    METHODS init_game.
    METHODS floorplan        RETURNING VALUE(result) TYPE string_table.
    METHODS execute          IMPORTING !command      TYPE string.
    METHODS create_help_html RETURNING VALUE(result) TYPE string.
    METHODS set_focus.
ENDCLASS.


CLASS zcl_axage_wizard_ui IMPLEMENTATION.
  METHOD create_help_html.
    result =
     `<pre>` &&
       '              _,._       ' && '<br>' &&
       '  .||,       /_ _\\\\     ' && '<br>' &&
       ' \.`'',/      |''L''| |     ' && '<br>' &&
       ' = ,. =      | -,| L     ' && '<br>' &&
       ' / || \    ,-''\"/,''`.    ' && '<br>' &&
       '   ||     ,''   `,,. `.  ' && '<br>' &&
       '   ,|____,'' , ,;'' \| |   ' && '<br>' &&
       '  (3|\    _/|/''   _| |   ' && '<br>' &&
       '   ||/,-''   | >-'' _,\\\\ ' && '<br>' &&
       '   ||''      ==\ ,-''  ,''  ' && '<br>' &&
       '   ||       |  V \ ,|    ' && '<br>' &&
       '   ||       |    |` |    ' && '<br>' &&
       '   ||       |    |   \   ' && '<br>' &&
       '   ||       |    \    \  ' && '<br>' &&
       '   ||       |     |    \ ' && '<br>' &&
       '   ||       |      \_,-'' ' && '<br>' &&
       '   ||       |___,,--")_\ ' && '<br>' &&
       '   ||         |_|   ccc/ ' && '<br>' &&
       '   ||        ccc/        ' && '<br>' &&
       '   ||                hjm ' && '<br>' &&
       `</pre>` &&

     |<h2>Help</h2><p>| &
     |<h3>Navigation</h3><ul>| &&
     |<li>MAP        <em>Show map/floor plan/world.</em>| &&
     |<li>N or NORTH <em>Walk to the room on the north side.</em>| &&
     |<li>E or EAST  <em>Walk to the room on the east side.</em>| &&
     `<li>S or SOUTH <em>Walk to the room on the south side.</em>` &&
     `<li>W or WEST  <em>Walk to the room on the west side.</em>` &&
     `<li>U or UP    <em>Go to the room upstairs.</em>` &&
     `<li>D or DOWN  <em>Go to the room downstairs.</em></ul><p>`.

    result = result &&
    |<h3>Interaction</h3>| &&
    |<ul><li>INV or INVENTORY <em>View everything you are carrying.</em>| &&
    `<li>LOOK <em>Describe your environment.</em>` &&
    `<li>LOOK object     <em>Have a closer look at the object in the room or in your inventory.</em>` &&
    `<li>PICKUP object   (or TAKE) <em>Pickup an object in the current place.</em>` &&
    `<li>DROP object     <em>Drop an object that you carry.</em>` &&
    `<li>OPEN object     <em>Open something that is in the room.</em></ul><p>`.

    result = result &&
    |<h3>Other</h3><ul>| &&
    `<li>ASK person            <em>Ask a person to tell you something.</em>` &&
    `<li>CAST spell            <em>Cast a spell you have learned before.</em>` &&
    `<li>WELD subject object   <em>Weld subject to the object if allowed.</em>` &&
    `<li>DUNK subject object   <em>Dunk subject into object if allowed.</em>` &&
    `<li>SPLASH subject object <em>Splash  subject into object.</em></ul>`.
  ENDMETHOD.

  METHOD execute.
    DATA(log) = engine->interprete( command = command
                                    auto_look = auto_look ).

    IF engine->mission_completed = abap_true.

      DATA(guild) = engine->new_room( name = 'Guild'
                                      descr = 'the Wizard''s Guild'
                                      state = 'recognized as a full wizard.'
                                      background = lcl_images=>congratulation( )
                                      cheat = lcl_texts=>cheat_hint( 'GUILD' ) ).

      engine->player->location = guild.
      log->success_msg( title = 'Mission completed'
                        subtitle = 'You did it!'
                        description = lcl_texts=>congratulation( )  ).
    ENDIF.

    current_location = |<h4>You are in { engine->player->location->description }</h4>|.
    anzahl_items = lines( engine->player->get_list( ) ).
    background_image = engine->player->location->get_image( ).
    cheat_sheet = engine->player->location->cheat.

    messages = log->t_msg.
    results = log->get( ).
  ENDMETHOD.

  METHOD floorplan.
    result = VALUE string_table(
      ( `+--------------------+` )
      ( `| Welding            |` )
      ( `|  Torch             |` )
      ( `|                    |` )
      ( `|       ATTIC        |` )
      ( `|                    |` )
      ( `+--------+  +--------+` )
      ( `         |__| ` )
      ( `  Ladder |  | ` )
      ( `+--------+  +--------+ +----------------+` )
      ( `|              Bucket| |                |` )
      ( `|mop                 | |                |` )
      ( `|     LIVING         | |        Well    |` )
      ( `|      ROOM          +-+                |` )
      ( `|                    Door    GARDEN     |` )
      ( `|  Sleeping          +-+                |` )
      ( `|   Wizard   Whiskey | |         Chain  |` )
      ( `+--------------------+ +-----+  +-------+` )
      ( `                         Door|  |        ` )
      ( `                       +-----+  +-------+` )
      ( `                       |Frog            |` )
      ( `                       |     POND       |` )
      ( `                       |         Potion |` )
      ( `                       +----------------+` ) ).
  ENDMETHOD.

  METHOD init_game.
    engine = NEW #( ).
    " Nodes
    DATA(living_room) = engine->new_room(
                             name = 'Living Room'
                             descr = 'the living-room of a wizard''s house.'
                             background = lcl_images=>living_room( )
                             cheat = lcl_texts=>cheat_hint( 'LIVINGROOM' ) ).
    DATA(attic)  = engine->new_room( name = 'Attic'
                                     descr = 'the attic.'
                                     background = lcl_images=>attic( )
                                     dark = abap_true
                                     state = 'The attic is dark'
                                     cheat = lcl_texts=>cheat_hint( 'ATTIC' )  ).
    DATA(garden) = engine->new_room( name = 'Garden'
                                       descr = 'a beautiful garden.'
                                       background = lcl_images=>garden( )
                                       cheat = lcl_texts=>cheat_hint( 'GARDEN' ) ).
    DATA(pond) = engine->new_room( name = 'Pond'
                                   descr = 'a pond with a frog'
                                   state = 'The pond is dark'
                                   dark = abap_true
                                   background = lcl_images=>pond( ) ).

    engine->map->add_room( living_room ).
    engine->map->add_room( attic ).
    engine->map->add_room( garden ).
    engine->map->add_room( pond ).

    engine->map->set_floor_plan( floorplan( ) ).

    living_room->set_exits( u = attic
                            e = garden ).
    attic->set_exits( d = living_room ).
    garden->set_exits( w = living_room
                       s = pond ).
    pond->set_exits( n = garden ).

    engine->player->set_location( living_room ).

    " LIVING ROOM**:
    "- When you **LOOK** around, you find a Fireplace, a Bookshelf, and an Old Painting.
    "- When you **LOOK** at the Fireplace, you find Ashes.
    "- When you **PICKUP** the Ashes, you obtain them in your **INVENTORY**.
    "- When you **OPEN** the Bookshelf, you find a Magic Tome.
    "- When you **LOOK** at the Magic Tome, you learn the spell "Illuminara", which can be used to light up dark places.
    "- When you **LOOK** at the Old Painting, you find a depiction of the three magical items you're searching for.

    DATA(wizard) = engine->new_actor( name = 'WIZARD' state = 'snoring loudly on the couch' descr = ''
                                      active = abap_false
                                      location = living_room ).
    wizard->add_sentences( VALUE #(  ( |Go and weld a Sunflower with the Ashes from the Fireplace| )
                                     ( |Now leave me alone...\n| )  ) ).
    wizard->add_inactive_sentences( VALUE #(
                                     ( |Combine three magical items to open a portal to the Wizard's Guild.| )
                                     ( |Find the Potion of Infinite Stars| )
                                     ( |Create the Orb of Sunlight and | )
                                     ( |the Staff of Eternal Moon. \n| )
                                     ( |Read the spellbook and let me sleep...\n| ) )     ).
    living_room->add( wizard ).

    DATA(whiskey) = engine->new_object( name = 'BOTTLE' state = 'on the floor' descr = 'whiskey'  ).
    living_room->add( whiskey ).

    DATA(bucket) = engine->new_object( name = 'BUCKET' state = 'on the floor' descr = 'with water'
     can_be_weld = abap_true
     can_be_splashed = abap_true
     can_be_splashed_on = abap_true
     can_be_dunked = abap_true
     can_be_dunked_into = abap_true ).
    living_room->add( bucket ).

    DATA(mop) = engine->new_object( name = 'MOP' state = 'on the floor' descr = ''
     can_be_dunked = abap_true
     can_be_dunked_into = abap_false ).
    living_room->add( mop ).

    DATA(content_of_fireplace) = engine->new_node( name = 'FirePlaceContent'  ).
    DATA(ashes) = engine->new_object( name = 'ASHES'
       descr = 'enchanted ashes'  state = 'from past magical fires'
       prefix = space
       can_be_weld = abap_true ).

    content_of_fireplace->add( ashes ).

    DATA(needed_to_open_fireplace) = engine->new_node( 'FirePlaceOpener' ).

    DATA(fireplace) = NEW ycl_axage_openable_thing(
      name = 'FIREPLACE'
      descr = 'carved with arcane symbols'
      state = 'its grate is filled with ashes'
      can_be_pickup = abap_false
      can_be_drop = abap_false
      content = content_of_fireplace
      needed  = needed_to_open_fireplace
      repository = engine ).
    living_room->add( fireplace ).

    DATA(bookshelf_key) = engine->new_object( name = 'KEY' descr = 'it is small' ).
    living_room->add( bookshelf_key ).

    DATA(needed_to_open_tome) = engine->new_node( 'BookOpener' ).

    DATA(content_of_tome) = engine->new_node( 'BookContent' ).
    content_of_tome->add( engine->new_spell( name = 'LUMI' prefix = ''
       descr = '"Illuminara", a spell which can light up dark places.' ) ).
    content_of_tome->add( engine->new_spell( name = 'PORTA' prefix = ''
       descr = '"Portallis", a spell which opens a portal.' ) ).

    DATA(tome) = NEW ycl_axage_openable_thing(
      name    = 'SPELLBOOK'
      descr   = 'Magic Tome with arcane spells'
      content = content_of_tome
      needed  = needed_to_open_tome
      repository = engine ).

    DATA(content_of_bookshelf) = engine->new_node( 'BookshelfContent' ).
    content_of_bookshelf->add( tome ).

    DATA(needed_to_open_bookshelf) = engine->new_node( 'BookshelfOpener' ).
    needed_to_open_bookshelf->add( bookshelf_key ).

    DATA(bookshelf) = NEW ycl_axage_openable_thing( name = 'BOOKSHELF'
                           descr = 'with magic tomes'
                           state = 'closed'
                           repository = engine
                           can_be_open = abap_true
                           can_be_pickup = abap_false
                           can_be_drop = abap_false
                           content = content_of_bookshelf
                           needed  = needed_to_open_bookshelf ).
    living_room->add( bookshelf ).

    DATA(painting) = engine->new_object( prefix = `an Old ` name = 'PAINTING'
       state = 'with the title The Guild''s Trial'
       descr = 'depiction of the Orb of Sunlight, the Potion of Infinite Stars, and the Staff of Eternal Moon'
     can_be_pickup = abap_false
     can_be_drop = abap_false ).
    living_room->add( painting ).

    DATA(letter) = engine->new_object( name = 'LETTER' state = 'from the Wizard''s Guild'
       descr = lcl_texts=>intro( )  ).
    living_room->add( letter ).

    " ATTIC**:

    "- The Attic is dark. Use "Illuminara" to light up the space.
    "- When you **LOOK** around, you find a Chest, a Workbench, and a Moon-crested Key.
    "- When you **PICKUP** the Moon-crested Key, you can use this to open the Shed in the Garden.
    "- When you **OPEN** the Chest, you find an old Magic Staff.
    "- When you **PICKUP** the Magic Staff and **DUNK** it into the Potion of Infinite Stars, then **SPLASH** the Orb of Sunlight onto the combined items, you obtain the Staff of Eternal Moon.

    DATA(magic_Staff) = engine->new_object( name = 'STAFF'
                       descr = 'an old Magic Staff'  state = ''
                       can_be_pickup = abap_true
                       can_be_drop = abap_true
                       can_be_weld = abap_false
                       can_be_open = abap_false
                       can_be_splashed = abap_true
                       can_be_splashed_on = abap_true
                       can_be_dunked = abap_true
                       can_be_dunked_into = abap_false ).

    DATA(content_of_chest) = engine->new_node( 'ChestContent' ).
    content_of_chest->add( magic_staff ).

    DATA(needed_to_open_chest) = engine->new_node( 'ChestOpener' ).
    " needed_to_open_chest->add( ).

    DATA(chest) = NEW ycl_axage_openable_thing( name = 'CHEST'
                           descr = 'large'
                           state = 'open'
                           repository = engine
                           can_be_open = abap_true
                           can_be_pickup = abap_false
                           can_be_drop = abap_false
                           content = content_of_chest
                           needed  = needed_to_open_chest ).
    attic->add( chest ).

    DATA(workbench) = engine->new_object( name = 'WORKBENCH'
      descr = 'on the corner'
       can_be_pickup = abap_false
       can_be_drop = abap_false ).
    attic->add( workbench ).

    DATA(mooncrest_key) = engine->new_object( name = 'BIGKEY' state = 'on the workbench'
      descr = 'it is moon-crested key' ).
    attic->add( mooncrest_key ).

    DATA(welding_torch) = engine->new_object( name = 'WELDING TORCH'
      descr = 'in the corner'
       can_weld = abap_true
       can_be_pickup = abap_false
       can_be_drop = abap_false ).
    attic->add( welding_torch ).

    " GARDEN**:

    "- When you **LOOK** around, you find a Pond, a Flower Bed, and a Shed.
    "- When you **LOOK** at the Flower Bed, you see a Sunflower.
    "- When you **PICKUP** the Sunflower and **WELD** it with the Ashes from the Fireplace, you obtain the Orb of Sunlight.
    "- The Shed is locked. The key can be found in the Attic.

    DATA(content_of_flowerbed) = engine->new_node( name = 'FlowerbedContent'  ).
    DATA(sunflower) = engine->new_object( name = 'SUNFLOWER'
       descr = 'a Sunflower'  state = 'in a Flower Bed'
       can_be_weld = abap_true ).

    content_of_flowerbed->add( sunflower ).

    DATA(needed_to_open_flowerbed) = engine->new_node( 'FlowerbedOpener' ).

    DATA(flowerbed) = NEW ycl_axage_openable_thing(
      name = 'FLOWERBED'
      descr = 'a flower bed'
      state = 'filled with flowers'
      can_be_pickup = abap_false
      can_be_drop = abap_false
      content = content_of_flowerbed
      needed  = needed_to_open_flowerbed
      repository = engine ).
    garden->add( flowerbed ).

    DATA(content_of_shed) = engine->new_node( 'ShedContent' ).

    DATA(needed_to_open_shed) = engine->new_node( 'ShedOpener' ).
    needed_to_open_shed->add( Mooncrest_key ).

    DATA(shed) = NEW ycl_axage_openable_thing( name = 'SCHED'
                           descr = 'in the garden'
                           state = 'closed'
                           repository = engine
                           can_be_open = abap_true
                           can_be_pickup = abap_false
                           can_be_drop = abap_false
                           content = content_of_shed
                           needed  = needed_to_open_shed ).
    garden->add( shed ).

    DATA(well) = engine->new_object( name = 'WELL' state = 'in front of you' descr = ''
      can_be_pickup = abap_false
      can_be_drop = abap_false
      can_be_dunked = abap_false
      can_be_dunked_into = abap_true
      can_be_splashed = abap_false
      can_be_splashed_on = abap_true ).
    garden->add( well ).

    DATA(chain) = engine->new_object( name = 'CHAIN' state = ' the floor' descr = ''
      can_be_weld = abap_true ).
    garden->add( chain ).

    " POND**:

    "- When you **LOOK** at the Pond, you notice that it's too dark to see anything.
    "- When you cast "Illuminara" on the Pond, you see a Bottle at the bottom.
    "- When you **PICKUP** the Bottle, you discover it's a Potion of Infinite Stars.

    DATA(potion) = engine->new_object( name = 'POTION' state = 'at the bottom'
                                       descr = 'of Infinite Stars'
                       can_be_pickup = abap_true
                       can_be_drop = abap_true
                       can_be_weld = abap_false
                       can_be_open = abap_false
                       can_be_splashed = abap_true
                       can_be_splashed_on = abap_false
                       can_be_dunked = abap_false
                       can_be_dunked_into = abap_true ).
    pond->add( potion ).

    DATA(frog) = engine->new_object( name = 'FROG' state = '' descr = ''  ).
    pond->add( frog ).

    mt_suggestion = VALUE #(
        ( descr = 'Display help text'  value = 'HELP' )
        ( descr = 'Go to the room on the north side'   value = 'NORTH' )
        ( descr = 'Go to the room on the south side'  value = 'SOUTH' )
        ( descr = 'Go to the room on the east side'   value = 'EAST' )
        ( descr = 'Go to the room on the west side'  value = 'WEST' )
        ( descr = 'Go to the room on the upstairs'    value = 'UP' )
        ( descr = 'Go to the room on the downstairs'   value = 'DOWN' )
        ( descr = 'Show Map/floor plan/Game world'  value = 'MAP' )

        ( descr = 'Inventary - Show everything you carry'  value = 'INVENTORY' )

        ( descr = 'What is in this place?' value = 'LOOK' )
        ( descr = 'Look (at) <object>'       value = 'LOOK' )
        ( descr = 'Pickup <object>'  value = 'PICKUP' )
        ( descr = 'Drop <object>'  value = 'DROP' )
        ( descr = 'Open <object>'  value = 'OPEN' )

        ( descr = 'Ask <person>'  value = 'ASK' )
        ( descr = 'Cast <spell>'  value = 'CAST' )
        ( descr = 'Weld <subject> <object>'  value = 'WELD' )
        ( descr = 'Dunk <subject> <object>'  value = 'DUNK' )
        ( descr = 'Splash <subject> <object>'  value = 'SPLASH' ) ).

    formatted_text = create_help_html( ).

    engine->combinations = VALUE #( BASE engine->combinations
                                         ( operation = ycl_axage=>c_action_weld
                                           name1     = 'ASHES'
                                           name2     = 'SUNFLOWER'
                                           result    = 'ORB'
                                           category  = ycl_axage=>c_combine_category_merge )
                                         ( operation = ycl_axage=>c_action_dunk
                                           name1     = 'STAFF'
                                           name2     = 'POTION'
                                           result    = 'MAGICSTAFF'
                                           category  = ycl_axage=>c_combine_category_into )
                                         ( operation = ycl_axage=>c_action_splash
                                           name1     = 'ORB'
                                           name2     = 'MAGICSTAFF'
                                           result    = 'MOONSTAFF'
                                           category  = ycl_axage=>c_combine_category_on ) ).
  ENDMETHOD.

  METHOD set_focus.
    app-client->cursor_set(  VALUE #( id = c_id_command
                                      cursorpos = '1'
                                      selectionstart = '1'
                                      selectionend = '1' ) ).
  ENDMETHOD.

  METHOD view_popup_input.
    DATA(popup) = z2ui5_cl_xml_view=>factory_popup( client ).
    popup->dialog(
       " contentheight = '200px'
       contentwidth  = '500px'
       title = 'Player Profile'
       icon = 'sap-icon://account'
       )->content(
           )->simple_form(
               )->label( 'Guild Aspirant''s Name'
               )->input( value = client->_bind_edit( player_name )
                         submit = client->_event( 'BUTTON_PLAYER_CONFIRM' )
       )->get_parent( )->get_parent(
       )->footer( )->overflow_toolbar(
           )->toolbar_spacer(
           )->button(
               text  = 'Save'
               press = client->_event( 'BUTTON_GAME_SAVE' )
               icon  = 'sap-icon://save'
               enabled = abap_false
           )->button(
               text  = 'Load'
               press = client->_event( 'BUTTON_GAME_LOAD' )
               icon  = 'sap-icon://load'
               enabled = abap_false
           )->button(
               text  = 'Cancel'
               press = client->_event( 'BUTTON_PLAYER_CANCEL' )
               icon  = 'sap-icon://reset'
           )->button(
               text  = 'Confirm'
               press = client->_event( 'BUTTON_PLAYER_CONFIRM' )
               type  = 'Emphasized'
               icon  = 'sap-icon://accept' ).

    client->popup_display( popup->stringify( ) ).
  ENDMETHOD.

  METHOD z2ui5_if_app~main.
    app-client = client.
    app-s_get  = client->get( ).

    mv_popup_name = ''.

    IF app-check_initialized = abap_false.
      app-check_initialized = abap_true.

      command = 'MAP'.
      init_game( ).
      help = engine->interprete( 'HELP' )->get( ).

      player_name = engine->player->name.
      mv_popup_name = 'POPUP_TO_INPUT_PLAYER'.

    ENDIF.

    CASE client->get( )-event.
      WHEN 'LOOK' OR 'INV' OR 'MAP' OR 'UP'
        OR 'DOWN' OR 'NORTH' OR 'SOUTH' OR 'EAST' OR 'WEST'
        OR 'HELP'.
        execute( client->get( )-event ).

      WHEN 'BUTTON_POST'.
        client->message_toast_display( |{ command } - send to the server| ).
        execute( command ).
        set_focus( ).

      WHEN 'POPUP_SETUP_PLAYER'.
        player_name = engine->player->name.
        mv_popup_name = 'POPUP_TO_INPUT_PLAYER'.

      WHEN 'BUTTON_PLAYER_CONFIRM'.
        engine->player->name = player_name.

      WHEN 'BUTTON_PLAYER_CANCEL'.
        client->message_toast_display( 'Player Setup - Cancel pressed' ).

      WHEN 'BUTTON_GAME_SAVE'.

      WHEN 'BUTTON_GAME_LOAD'.

      WHEN 'BACK'.
        client->nav_app_leave( client->get_app( client->get( )-id_prev_app_stack  ) ).
    ENDCASE.

    DATA(lo_main) = z2ui5_cl_xml_view=>factory( client )->shell( ).
    DATA(page) = lo_main->page(
      id =           'id_page'
      title          = 'The Wizard''s Adventure Game'
      navbuttonpress = client->_event( 'BACK' )
      shownavbutton  = abap_true ).

    page->header_content(
      )->toolbar(        " )->overflow_toolbar(
        )->button(
            text  = 'Look'
            press = client->_event( 'LOOK' )
            icon  = 'sap-icon://show'
        )->button(
             text = 'Map'
             press = client->_event( 'MAP' )
             icon  = 'sap-icon://map-2'
        )->button( text = 'Inventory'
                   class = 'sapUiTinyMarginBeginEnd'
                   press = client->_event( 'INV' )
                   icon = 'sap-icon://menu'
             )->get( )->custom_data(
                        )->badge_custom_data(
                            key     = 'items'
                            value   = anzahl_items
                            visible = abap_true
        )->get_parent( )->get_parent(
        )->button(
           text  = 'Profile'
           icon  = 'sap-icon://account'
           press = client->_event( 'POPUP_SETUP_PLAYER' )

        )->toolbar_spacer(

        )->button(
             text = 'UP'
             press = client->_event( 'UP' )
             icon  = 'sap-icon://arrow-top'
        )->button(
             text = 'DOWN'
             press = client->_event( 'DOWN' )
             icon  = 'sap-icon://arrow-bottom'
        )->button(
             text = 'North'
             press = client->_event( 'NORTH' )
             icon  = 'sap-icon://navigation-up-arrow'
        )->button(
             text = 'South'
             press = client->_event( 'SOUTH' )
             icon  = 'sap-icon://navigation-down-arrow'
        )->button(
             text = 'West'
             press = client->_event( 'WEST' )
             icon  = 'sap-icon://navigation-left-arrow'
        )->button(
             text = 'East'
             press = client->_event( 'EAST' )
             icon  = 'sap-icon://navigation-right-arrow'

        )->button(
             text = 'Help'
             press = client->_event( 'HELP' )
             icon  = 'sap-icon://sys-help'
       )->get_parent( ).

    IF engine->player->exists( 'ORB' ).
      page->generic_tag(
                arialabelledby = 'genericTagLabel'
                text           = 'Orb of Sunlight'
                " design         = 'StatusIconHidden'
                status         = 'Success'
                class          = 'sapUiSmallMarginBottom'
            )->object_number(
                state      = 'Success'
                emphasized = 'true'
                number     = '1'
                unit       = 'Orb' ).
    ENDIF.

    IF engine->player->exists( 'MOONSTAFF' ).
      page->generic_tag(
            arialabelledby = 'genericTagLabel'
            text           = 'Staff of Eternal Moon'
            " design         = 'StatusIconHidden'
            status         = 'Success'
            class          = 'sapUiSmallMarginBottom'
            )->object_number(
                state      = 'Success'
                emphasized = 'false'
                number     = '1'
                unit       = 'Staff' ).
    ENDIF.

    IF engine->player->exists( 'POTION' ).
      page->generic_tag(
           arialabelledby = 'genericTagLabel'
           text           = 'Potion of Infinite Stars'
           status         = 'Success'
           " design         = 'StatusIconHidden'
           class          = 'sapUiSmallMarginBottom'
           )->object_number(
               state      = 'Success'
               emphasized = 'true'
               number     = '1'
               unit       = 'Bottle' ).
    ENDIF.

    DATA(grid1) = page->grid( 'L6 M12 S12' )->content( 'layout' ).

    grid1->simple_form(
        title =  'abap2UI5 and AXAGE Adventure Game - The Trial'
        editable = abap_true
        )->content( 'form'
            )->label( 'Always Look'
              )->switch(
              state         = client->_bind_edit( auto_look )
              customtexton  = 'Yes'
              customtextoff = 'No'

            )->label( 'Command'
            )->input(
                    id              = c_id_command
                    showClearIcon   = abap_true
                    submit          = client->_event( `BUTTON_POST` )
                    value           = client->_bind_edit( command )
                    placeholder     = 'enter your next command'
                    suggestionitems = client->_bind( mt_suggestion )
                    showsuggestion  = abap_true )->get(

                        )->suggestion_items( )->get(
                           )->list_item(
                               text = '{VALUE}'
                               additionaltext = '{DESCR}'

             )->get_parent( )->get_parent(
               )->hbox( justifycontent = `SpaceBetween`
                  )->button(
                     text = `Go` press = client->_event( `BUTTON_POST` )
                     type = `Emphasized`
                     icon  = 'sap-icon://paper-plane'
             )->get_parent( )->get_parent(

             )->get_parent(

              )->scroll_container( height = '30%' vertical = abap_true focusable = abap_false
             )->message_view(
                 items = client->_bind( messages )
                 groupitems = abap_true
                 )->message_item(
                     type        = `{TYPE}`
                     title       = `{TITLE}`
                     subtitle    = `{SUBTITLE}`
                     description = `{DESCRIPTION}`
                     groupname   = `{GROUP}` ).

    IF background_image IS NOT INITIAL.

      grid1->simple_form( |Location of { engine->player->name }|
        )->content( 'form'
        )->vbox( 'sapUiSmallMargin'
                )->formatted_text( Current_Location
         )->carousel(
           )->image( src = background_image
           )->vbox( 'sapUiMediumMargin'
                     )->formatted_text( lcl_texts=>hint( engine->player->location->name )
             )->get_parent(
           )->vbox( 'sapUiMediumMargin'
                     )->formatted_text( Cheat_Sheet
             )->get_parent( ).

    ENDIF.

    " page->grid( 'L8 M8 S8' )->content( 'layout' ).
    DATA(grid2) = page->grid( 'L6 M8 S8' )->content( 'layout' ).

    grid2->simple_form( title = 'Game Console' editable = abap_true )->content( 'form'
        )->code_editor( value = client->_bind( results )
                        editable = 'false'
                        type = `plain_text`
                        height = '600px' ).

    grid2->simple_form( title = 'Quest for a Wizard''s Guild Aspirant' editable = abap_true )->content( 'form'
         )->vbox( 'sapUiSmallMargin'
                )->formatted_text( formatted_text ).

    page->footer( )->overflow_toolbar(
        )->button(
            text  = 'Pickup'
            press = client->_event( 'PICKUP' )
            enabled = abap_false
            icon = 'sap-icon://cart-3'
        )->button(
            text  = 'Drop'
            press = client->_event( 'DROP' )
            enabled = abap_false
            icon = 'sap-icon://cart-2'
        )->button(
            text  = 'Open'
            press = client->_event( 'OPEN' )
            enabled = abap_false
            icon = 'sap-icon://outbox'
        )->button(
            text  = 'Ask'
            press = client->_event( 'ASK' )
            enabled = abap_false
            icon = 'sap-icon://travel-request'
        )->button(
            text  = 'Cast'
            press = client->_event( 'CAST' )
            enabled = abap_false
            icon = 'sap-icon://activate'
        )->button(
            text  = 'Weld'
            press = client->_event( 'WELD' )
            enabled = abap_false
                )->toolbar_spacer(
        )->link(
             text = 'Credits'
             href  = 'https://github.com/Ennowulff/axage'
        )->link(
             text = 'abap2UI5'
             href  = 'https://github.com/oblomov-dev/abap2ui5'
        )->link(
             text = 'AXAGE+UI5'
             href  = 'https://github.com/jung-thomas/axage_example'
        )->link(
             text = 'Land Of Lisp'
             href  = 'http://landoflisp.com' ).

    CASE mv_popup_name.

      WHEN 'POPUP_TO_INPUT_PLAYER'.
        view_popup_input( client ).

    ENDCASE.

    set_focus( ).
    client->view_display( lo_main->stringify( ) ).
  ENDMETHOD.
ENDCLASS.
