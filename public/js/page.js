$( document ).ready( function() {
    $( 'table.sortable' ).tablesorter(
        {
            widgets: ['zebra'],
            cssAsc: 'sort-up',
            cssDesc: 'sort-down',
        }
    );
    $( '.error,.notice,.success' ).fadeIn( 2000 );
    
    $.scrollTo( '.new', 500 );
    $( '.new' ).fadeIn( 2000 );
} );