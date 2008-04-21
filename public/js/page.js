$( document ).ready( function() {
    $( 'table.sortable' ).tablesorter(
        {
            widgets: ['zebra'],
            cssAsc: 'sort-down',
            cssDesc: 'sort-up',
        }
    );
    $( '.error,.notice,.success' ).fadeIn( 2000 );
    
    $.scrollTo( '.new', 500 );
    $( '.new' ).fadeIn( 2000 );
} );