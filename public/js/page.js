$( document ).ready( function() {
    $( 'table.sortable' ).tablesorter(
        { widgets: ['zebra'] }
    );
    
    $( '.error,.notice,.success' ).hide().fadeIn( 2000 );
} );