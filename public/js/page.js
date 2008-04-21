$( document ).ready( function() {
    $( 'table.sortable' ).tablesorter(
        { widgets: ['zebra'] }
    );
    $( '.error,.notice,.success' ).fadeIn( 2000 );
    
    $.scrollTo( '.new', 500 );
    $( '.new' ).fadeIn( 2000 );
} );