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
  J.win_bind('form','submit',J.formSubmit);
  J.win_bind('ul.navigation li a','click',J.menuClick);
  J.win_bind('.editable','click',J.toggleColStat);
});

J={
  combine: function(old_o,new_o){
    for (var k in new_o) {
      if (!old_o[k]){old_o[k]=new_o[k]}
    }
    return old_o;
  },
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
    var t=J.known_types[Object.prototype.toString.call(o).replace(/\S+\s/,'').replace(/\]/,'')]||'obj';      
    return test ? t===test : t;
  },
  get_callbacks: function(fn){
    var that=this;
    if (J.type(fn,'fn')) {
      var cb=function() {
        fn.apply(that,arguments);
      }
    } else {
      var cb={};
      for (i in fn) {
        cb[i]=J.get_callbacks.call(that,fn[i]);
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
  ajax:function(params){
    var r=new XMLHttpRequest();
    r.onreadystatechange = function() {
      if(r.readyState === 1) {
            params.load && params.load();
      } else if(r.readyState === 4) {
        params.always && params.always();
        if(r.status>199 && r.status<300) {
          params.success && params.success(JSON.parse(r.responseText))
        } else {
          params.error && params.error(r.status, r.responseText);
        }
      }
    };
    r.open(params.verb||'post',params.url,params.async||true,params.user,params.password);
    r.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
    r.setRequestHeader('Content-type', 'application/x-www-form-urlencoded; charset=utf-8')
    r.send(params.data);
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
          $('#'+frm_id+' [id$=__'+col+']').addClass('errorCol').parent().append(Reggae.call(["p",{"class":"errorMsg"},attrs.error_details[col]]));
        }
      }
    },
  },
  make_ajax_params:function(params){
    return J.combine(params,
        J.combine(J.get_callbacks.call(this,J.ajax_defaults),{
          dataType:'json',
          url:this.href || this.action,
          type: this.method ? this.method.toUpperCase() : 'GET'
        })
    );
  },
  menuClick:function(e){
    e.preventDefault();
    var target='#'+$(this).parent().attr('class').replace(/__nav$/,'__content')
    J.ajax(J.make_ajax_params.call(this,{verb:'get',success:function(json){Reggae.call(json,target)}}))
  },
  formSubmit:function(e){
    e.preventDefault();
    J.ajax(J.make_ajax_params.call(this,{data:$('#'+this.id).serialize()}));
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
