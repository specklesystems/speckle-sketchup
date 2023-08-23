// Globals
var inputbox;


// Init
$(document).ready( function() {
  inputbox = new Inputbox();
  window.location = 'skp:Inputbox_ready';
  $('.group h2').live('click', UI.toggle_content);
});


// Class Inputbox
function Inputbox()
{
  this.bridge_id = 'RUBY_Inputbox_get_value';
  this.align = 0.6;
}

Inputbox.prototype.CT_LIST      = 1
Inputbox.prototype.CT_RADIOBOX  = 2

Inputbox.prototype.init_html = function(options)
{
  var body = $('body');
  
  if ( 'align' in options ) {
    this.align = options.align;
  }
  
  // Input bridge between JS and Ruby
  body.append('<input type="hidden" id="'+this.bridge_id+'" />');
  // Footer
  var footer = $('<div id="footer"/>').appendTo(body);
  
  var cmdOk = $('<a class="button normal"/>').appendTo( footer );
  cmdOk.addClass('button normal');
  cmdOk.attr('id', 'cmdAccept');
  cmdOk.text( options.accept_label );
  cmdOk.click(function() {
    // Set Checkbox values to reflect checked state so SU Ruby's
    $('input[type=checkbox]').val( function(index,value){
      return $(this).is(':checked').toString()
    } );
    // Set Radiobox values to reflect checked state so SU Ruby's
    $('input[type=radio]:checked').each( function(index){
      name = $(this).attr('name');
      $('#'+name).val( $(this).val() );
    } );
    window.location = 'skp:Inputbox_accept';
  });
  
  var cmdCancel = $('<a class="button normal"/>').appendTo( footer );
  cmdCancel.addClass('button normal');
  cmdCancel.attr('id', 'cmdCancel');
  cmdCancel.text( options.cancel_label );
  cmdCancel.click(function() {
    window.location = 'skp:Inputbox_cancel';
  });
  
  $(document).keydown( function(event) {
    switch ( event.keyCode ) {
    case 13: // Enter
      $('#cmdAccept').click();
      break;
    case 27: // ESC
      $('#cmdCancel').click();
      break;
    }
  });
  
  // Content frame
  var content = $('<div id="content"/>').appendTo(body);
  $(window).resize(this.resize);
  this.resize()
}

Inputbox.prototype.bridge = function()
{
  return $('#'+this.bridge_id);
}

Inputbox.prototype.add_control = function(control)
{
  // Container
  var parent = this.add_container(control);
  // Label
  this.add_label(control, parent);
  // Input elements
  var div = $('<div/>').appendTo(parent);
  div.css('width', this.align_percent() );
  //if ( control.value instanceof Array ) {
  if ( 'options' in control ) {
    // When no type is explicitly set, use list
    var list_type = ( 'type' in control ) ? control.type : this.CT_LIST;
    switch ( list_type ) {
    case this.CT_RADIOBOX:
      this.add_radiolist(control, div); break;
    default:
      this.add_list(control, div);
    }
  } else if ( control.value === true || control.value === false ) {
    this.add_checkbox(control, div);
  } else {
    this.add_textbox(control, div);
  }
  // Description
  this.add_description(control, parent);
}

Inputbox.prototype.get_value = function(id) {
  control = $('#'+id);
  var value = control.val();
  if ( value instanceof Array ) {
    value = value.join('||')
  }
  this.bridge().val( value );
}

Inputbox.prototype.align_percent = function() {
  return (this.align * 100) + '%';
}

// Private

Inputbox.prototype.resize = function()
{
  var new_height = $(window).height() - $('#footer').outerHeight();
  var diff = $('#content').outerHeight() - $('#content').height();
  new_height -= diff;
  $('#content').css('height', new_height);
}

Inputbox.prototype.add_container = function(control) {
  var $parent;
  if ( 'group' in control ) {
    $parent = $('div.group > h2').filter(function(){
      return $(this).text() == control.group;
    }).parent();
    if ( $parent.length < 1 ) {
      $parent = $('<div class="group"/>').appendTo( '#content' );
      var $header = $('<h2/>').appendTo( $parent );
      $header.text( control.group );
      $('<div/>').appendTo( $parent );
    }
    $parent = $parent.children('div');
  } else {
    $parent = $('#content');
  }
  $container = $('<div class="container"/>');
  if ( 'tooltip' in control ) {
    $container.attr('title', control.tooltip);
  }
  return $container.appendTo( $parent );
}

Inputbox.prototype.add_checkbox = function(control, parent) {
  var c = $('<input type="checkbox"/>').appendTo( parent );
  c.attr( 'id', control.id );
  c.prop( 'checked', control.value );
  c.val( control.value );
  return c;
}

Inputbox.prototype.add_label = function(control, parent) {
  var l = $('<label/>').appendTo( parent );
  l.attr( 'for', control.id );
  l.text( control.label + ':' );
  l.css('right', this.align_percent() );
  return l;
}

/* (!) Add foldable descriptions? */
Inputbox.prototype.add_description = function(control, parent) {
  if ( 'description' in control ) {
    var d = $('<div class="description">').appendTo( parent );
    d.text( control.description );
    return d
  }
  return null;
}

Inputbox.prototype.add_list = function(control, parent) {
  var list = $('<select/>').appendTo( parent );
  list.attr( 'id', control.id );
  if ( 'size' in control ) {
    list.attr( 'size', control.size );
  }
  if ( 'multiple' in control && control.multiple ) {
    list.prop( 'multiple', 'multiple' );
  }
  list_items = this.sort_list(control);
  for (key in list_items) {
    value = list_items[key];
    list_item = $('<option/>').appendTo( list );
    list_item.text( value );
    list_item.val( value );
  }
  list.val(control.value);
  return list;
}

Inputbox.prototype.add_radiolist = function(control, parent) {
  var form = $('<form/>').appendTo( parent );
  var data = $('<input type="hidden"/>').appendTo( form );
  data.attr( 'id', control.id );
  var list = $('<p/>').appendTo( form );
  list_items = this.sort_list(control);
  for (key in list_items) {
    value = list_items[key];
    // Label
    list_item = $('<label/>').appendTo( list );
    // Radio
    i = $('<input type="radio"/>').appendTo( list_item );
    i.attr( 'name', control.id );
    i.val( value );
    // Label Text
    list_item.append( value );
  }
  //list.find('input[value='+control.value+']').is(':checked');
  list.find('input[value='+control.value+']').prop('checked', true);
  return form;
}

Inputbox.prototype.add_textbox = function(control, parent) {
  var i = $('<input type="text">').appendTo( parent );
  i.attr( 'id', control.id );
  i.val( control.value );
  return i;
}

Inputbox.prototype.sort_list = function(control) {
  if ( 'order' in control && control.order != 0 ) {
    if ( 'natrual_order' in control && control.natrual_order ) {
      list = control.options.sort(naturalSort);
    } else {
      list = control.options.sort();
    }
    if ( control.order < 0 ) {
      list = list.reverse();
    }
  } else {
    list = control.options;
  }
  return list;
}

// Debug

Inputbox.prototype.debug = function() {
  this.bridge().val( $('body').html() );
}