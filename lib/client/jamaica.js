RESTRICT_HIDE=1;
RESTRICT_RO=2;
RESTRICT_REQ=4;
NAME_INDEX=1;
TYPE_INDEX=PROPS_INDEX=2;
RESTRICTIONS_INDEX=2;
VALUE_INDEX=3;
String.prototype.humanize=function(){return $(this.replace(/^_/,'').split('_')).map(function(w){return w[0].toUpperCase()+w.slice(1)}).join(' ');}
$.domReady(function(){
  Reggae.call(_jamaica_json,'body');
//  j.win_bind('form','submit',j.formSubmit);
//  j.win_bind('ul.navigation li a','click',j.menuClick);
//  j.win_bind('.editable','click',j.toggleColStat);
});

j={
  known_types:{
    'Function': 'fn',
    'Object': 'obj',
    'Number': 'num',
    'String': 'str',
    'Boolean': 'bool',
    'Regexp': 'regx',
    'Date': 'date',
    'Undefined': 'undef',
    'Null': 'null',
    'Array': 'arr'
  },
  type:function(o,test) {
    var t=j.known_types[Object.prototype.toString.call(o).replace(/\S+\s/,'').replace(/\]/,'')]||'obj';      
    return test ? t===test : t;
  },
  get_callbacks: function(fn){
    var that=this;
    if (j.type(fn,'fn')) {
      var cb=function() {
        fn.apply(that,arguments);
      }
    } else {
      var cb={};
      for (i in fn) {
        cb[i]=j.get_callbacks.call(that,fn[i]);
      }
    }
    return cb;
  },
  win_bind:function(selector,evt,fn){
    window.addEventListener(evt, function(e){
      if ($(e.target).is(selector)){
        fn.call(e.target,e);
      }
    });
  },
  ajax_defaults:{
    load:function(){$('body').css('cursor','wait')},
    always:function(){$('body').css('cursor','default');},
    success:function(json){Reggae.call(json,'#'+this.id); },
    error:function(stat,json){
      var err=JSON.parse(json);
      var attrs=err[1];
      var frm_id=this.id;
      if (attrs.error_type=='validation') {
        for (col in attrs.error_details) {
          $('#'+frm_id+' [id$=__'+col+']').addClass('errorCol').after(Reggae.call(["p",{"class":"errorMsg"},attrs.error_details[col]]).toDom());
        }
      }
    },
  },
  make_ajax_params:function(params){
    return $.aug(params,
        $.aug(j.get_callbacks.call(this,j.ajax_defaults),{
          dataType:'json',
          url:this.href || this.action,
          type: this.method ? this.method.toUpperCase() : 'GET'
        })
    );
  },
  menuClick:function(e){
    e.preventDefault();
    var target='#'+$(this).parent().attr('class').replace(/__nav$/,'__content')
    $.ajax(j.make_ajax_params.call(this,{success:function(json){Reggae.call(json,target)}}))
  },
  formSubmit:function(e){
    e.preventDefault();
    $.ajax(j.make_ajax_params.call(this,{data:$.serialize(this.id)}))
  },
  toggleColStat:function(e){
    $('#',this.id).toggleClass("editing");
    $('#',this.id).toggleClass("editable");
    if($(this).hasClass("editing")){$(this).children("input,textarea").focus();}
  },
  colEditKeypress:function(e){
  },
  instanceActionClick:function(e){
  },
  deleteResource:function(e){
  },
}
