$( document ).ready( function() {
    $( 'table.sortable' ).tablesorter(
        {
            widgets: ['zebra'],
            cssAsc: 'sort-up',
            cssDesc: 'sort-down'
        }
    );
    $( '#ticket-list' ).tablesorter(
        {
            widgets: ['zebra'],
            cssAsc: 'sort-up',
            cssDesc: 'sort-down',
            sortList: [
                [ 6, 0 ], [ 3, 1 ], [ 7, 0 ], [ 5, 1 ]
            ]
        }
    );
    
    $( '#filter-toggle' ).click( function() {
        $( '#filter' ).toggle( 'normal' );
        return false;
    } );
        
    
    $( '.error,.notice,.success' ).fadeIn( 2000 );
    
    if( $( '.new' ).size() > 0 ) {
        $.scrollTo( '.new', 500 );
        $( '.new' ).fadeIn( 2000 );
    }
    
    $( '#comment-editor, #description-editor' ).markItUp( {
        previewParserPath: "/markdown_preview", // path to your Markdown parser
        onShiftEnter: { keepDefault:false,    openWith:'\n\n' },
    markupSet: [         
        {name:'First Level Heading', key:"1", placeHolder:'Your title here...', openWith:"\n", 
         closeWith:function(h) {
            heading1 = '';
            n = $.trim(h.selection||h.placeHolder).length;
            for(i = 0; i < n; i++)    {
                heading1 += '=';    
            }
            return '\n'+heading1+'\n';
        }},
        {name:'Second Level Heading', key:"2", placeHolder:'Your title here...', openWith:"\n", 
         closeWith:function(h) {
            heading2 = '';
            n = $.trim(h.selection||h.placeHolder).length;
            for(i = 0; i < n; i++)    {
                heading2 += '-';    
            }
            return '\n'+heading2+'\n';
        }},
        {name:'Heading 3', key:"3", openWith:'### ', placeHolder:'Your title here...' },
        {name:'Heading 4', key:"4", openWith:'#### ', placeHolder:'Your title here...' },
        {name:'Heading 5', key:"5", openWith:'##### ', placeHolder:'Your title here...' },
        {name:'Heading 6', key:"6", openWith:'###### ', placeHolder:'Your title here...' },                            
        {separator:'---------------' },        
        {name:'Bold', key:"B", openWith:'**', closeWith:'**'},
        {name:'Italic', key:"I", openWith:'_', closeWith:'_'},
        {separator:'---------------' },
        {name:'Bulleted List', openWith:'- ' },
        {name:'Numeric List', openWith:function(h) {
            return h.line+'. ';
        }},
        {separator:'---------------' },
        {name:'Picture', key:"P", replaceWith:'![[![Alternative text]!]]([![Url:!:http://]!] "[![Title]!]")'},
        {name:'Link', key:"L", openWith:'[', closeWith:']([![Url:!:http://]!] "[![Title]!]")', placeHolder:'Your text to link here...' },
        {separator:'---------------'},    
        {name:'Quotes', openWith:'> '},
        {name:'Code Block / Code', openWith:'(!(\t|!|`)!)', closeWith:'(!(`)!)'},                                                                    
        {separator:'---------------'},
        {name:'Preview', call:'preview', className:"preview"}
    ]
    } );
} );